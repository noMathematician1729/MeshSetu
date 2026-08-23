import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'mesh_gatt.dart';
import 'advertising_budget.dart';
import 'advertising_tier.dart';
import 'sos_advertisement.dart';
import 'async_lock.dart';
import '../model/model.dart';

/// Port of `in.meshsetu.ble.MeshAdvertiser` / `MeshScanner` (Kotlin
/// `BleDiscovery.kt`).
///
/// Deviations from the Kotlin source:
/// - `universal_ble`'s `startAdvertising` doesn't expose raw BLE
///   service-data (only `services`, `localName`, `manufacturerData`), so
///   [DiscoveryMetadata] rides as typed manufacturer data instead. This
///   turned out to match what the
///   Kotlin source independently switched to as well (upstream hit the same
///   31-byte legacy advertising-response budget problem).
/// - `scan` is time-bounded but also accepts a cancellation future so a
///   foreground service can release the radio immediately on shutdown.
abstract final class MeshAdvertiser {
  static final AsyncLock _advertisingLock = AsyncLock();
  static int _campaignGeneration = 0;
  static bool _sosCampaignActive = false;
  static bool _sosConcurrentExtended = false;
  static DiscoveryMetadata? _activeMetadata;
  static BlePeripheralCapabilities? _capabilities;
  static String _advertisingTier = 'legacy_1m';
  static String? _extendedFallbackReason;

  static BlePeripheralCapabilities? get capabilities => _capabilities;
  static String get advertisingTier => _advertisingTier;
  static String? get extendedFallbackReason => _extendedFallbackReason;

  /// The metadata this advertiser has been asked to broadcast, set on every
  /// [start] call regardless of whether the platform confirms advertising.
  /// [reassert] uses this so it can retry after an initial failed [start],
  /// not just after a previously verified session.
  static DiscoveryMetadata? _desiredMetadata;

  /// True once [start] has been called with metadata (intent), even if the
  /// platform has not yet confirmed [PeripheralAdvertisingState.advertising].
  /// [reassert] can attempt a first-time start when this is true and
  /// [_activeMetadata] is still null.
  static bool get isIntendedToAdvertise =>
      _activeMetadata != null || _desiredMetadata != null;

  static Future<void> start(DiscoveryMetadata metadata) {
    _desiredMetadata = metadata;
    return _advertisingLock.synchronized(() async {
      ++_campaignGeneration;
      await _startDiscoveryLocked(metadata);
    });
  }

  static Future<void> _startDiscoveryLocked(DiscoveryMetadata metadata) async {
    _desiredMetadata = metadata;
    final previousMetadata = _activeMetadata;
    final payload = MeshGatt.manufacturerPayload(
      MeshGatt.discoveryPayloadType,
      metadata.encode(),
    );
    final includeTxPower = BleAdvertisingBudget.fits(
      manufacturerPayloadBytes: payload.length,
      includeTxPower: true,
    );
    try {
      _capabilities = await UniversalBlePeripheral.getCapabilities();
      final tierDecision = MeshAdvertisingTierPolicy.select(_capabilities!);
      final canAttemptExtended = tierDecision.usesExtended;
      _extendedFallbackReason = tierDecision.reason;
      await _ensureIdleLocked();
      await UniversalBlePeripheral.startAdvertising(
        services: const [MeshGatt.service],
        manufacturerData: ManufacturerData(MeshGatt.manufacturerId, payload),
        platformConfig: PeripheralPlatformConfig(
          android: PeripheralAndroidOptions(
            addManufacturerDataInScanResponse: false,
            addServicesInScanResponse: true,
            includeTxPowerLevel: includeTxPower,
          ),
        ),
      );
      final state = await _waitForAdvertising();
      if (state != PeripheralAdvertisingState.advertising) {
        throw StateError('platform advertising state is ${state.name}');
      }
      _advertisingTier = 'legacy_1m';
      if (canAttemptExtended) {
        try {
          await UniversalBlePeripheral.startExtendedAdvertising(
            services: const [MeshGatt.service],
            manufacturerData: ManufacturerData(
              MeshGatt.manufacturerId,
              payload,
            ),
            platformConfig: PeripheralPlatformConfig(
              android: PeripheralAndroidOptions(includeTxPowerLevel: true),
            ),
          );
          _advertisingTier = 'legacy_1m+coded_extended';
        } catch (error) {
          // Extended advertising is an optimization. A controller can report
          // support and still reject a second set because of OEM resources.
          _extendedFallbackReason = error.toString();
        }
      } else if (_capabilities?.supportsExtendedAdvertising == true) {
        _extendedFallbackReason =
            'coded PHY or multiple-advertiser support unavailable';
      }
      _capabilities = await UniversalBlePeripheral.getCapabilities();
      _activeMetadata = metadata;
    } catch (error) {
      _activeMetadata = previousMetadata;
      // A failed start remains an intent until the caller explicitly calls
      // stop(), so the liveness watchdog can retry after radio recovery.
      _desiredMetadata = metadata;
      throw StateError('BLE advertising verification failed: $error');
    }
  }

  static Future<PeripheralAdvertisingState> _waitForAdvertising() =>
      _waitForState(
        (state) =>
            state == PeripheralAdvertisingState.advertising ||
            state == PeripheralAdvertisingState.error,
        const Duration(seconds: 3),
      );

  static Future<PeripheralAdvertisingState> _waitForState(
    bool Function(PeripheralAdvertisingState state) done,
    Duration timeout,
  ) async {
    final result = Completer<PeripheralAdvertisingState>();
    late final StreamSubscription<BlePeripheralAdvertisingStateChanged>
    subscription;
    subscription = UniversalBlePeripheral.advertisingStateStream.listen((
      event,
    ) {
      if (!result.isCompleted && done(event.state)) {
        result.complete(event.state);
      }
    });
    Timer? timer;
    try {
      final current = await UniversalBlePeripheral.getAdvertisingState();
      if (done(current)) result.complete(current);
      timer = Timer(timeout, () async {
        if (result.isCompleted) return;
        result.complete(await UniversalBlePeripheral.getAdvertisingState());
      });
      return await result.future;
    } finally {
      timer?.cancel();
      await subscription.cancel();
    }
  }

  /// Re-issues [start] with the last-known or desired discovery metadata.
  /// Uses [_activeMetadata] (previously verified) when available, otherwise
  /// falls back to [_desiredMetadata] so the first-ever start can be retried
  /// after an initial failure. Native Android rejects a second start while
  /// the previous advertiser is active, so the reassert path explicitly
  /// reaches idle before starting again.
  /// A no-op if neither [_activeMetadata] nor [_desiredMetadata] is set
  /// (i.e. [start] has never been called, or [stop] has been called).
  static Future<void> reassert() => _advertisingLock.synchronized(() async {
    if (_sosCampaignActive) return;
    final metadata = _activeMetadata ?? _desiredMetadata;
    if (metadata == null) return;
    ++_campaignGeneration;
    await _startDiscoveryLocked(metadata);
  });

  static Future<PeripheralAdvertisingState> _waitForIdle() => _waitForState(
    (state) =>
        state == PeripheralAdvertisingState.idle ||
        state == PeripheralAdvertisingState.error,
    const Duration(seconds: 1),
  );

  static Future<void> _ensureIdleLocked() async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await UniversalBlePeripheral.stopAdvertising();
        final state = await _waitForIdle();
        if (state == PeripheralAdvertisingState.idle) return;
        lastError = StateError('platform advertising state is ${state.name}');
      } catch (error) {
        lastError = error;
      }
      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    throw StateError('BLE advertising could not return to idle: $lastError');
  }

  static Future<void> stop() => _advertisingLock.synchronized(() async {
    ++_campaignGeneration;
    _activeMetadata = null;
    _desiredMetadata = null;
    _capabilities = null;
    _advertisingTier = 'legacy_1m';
    _extendedFallbackReason = null;
    _sosConcurrentExtended = false;
    _sosCampaignActive = false;
    await _ensureIdleLocked();
  });

  static const Duration compactSosBroadcastDuration = Duration(seconds: 24);
  static const Duration compactSosBurstDuration = Duration(seconds: 4);
  static const Duration compactDiscoveryBurstDuration = Duration(seconds: 2);

  /// Alternates compact SOS and normal discovery advertising. The SOS bursts
  /// cover scanner idle windows while discovery bursts keep this device
  /// connectable for GATT custody transfer.
  static Future<void> broadcastSos(
    MeshSosAdvertisement alert,
    DiscoveryMetadata discovery, {
    Duration duration = compactSosBroadcastDuration,
    Duration sosBurst = compactSosBurstDuration,
    Duration discoveryBurst = compactDiscoveryBurstDuration,
    FutureOr<void> Function()? onStarted,
    FutureOr<void> Function()? onRestored,
  }) async {
    final campaign = ++_campaignGeneration;
    final deadline = DateTime.now().add(duration);
    _sosCampaignActive = true;
    var started = false;
    try {
      while (_campaignGeneration == campaign &&
          DateTime.now().isBefore(deadline)) {
        await _advertisingLock.synchronized(() async {
          if (_campaignGeneration != campaign) return;
          await _startSosLocked(alert);
        });
        if (!started) {
          started = true;
          await onStarted?.call();
        }
        await Future<void>.delayed(sosBurst);
        if (_campaignGeneration != campaign) break;
        await _advertisingLock.synchronized(() async {
          if (_campaignGeneration != campaign) return;
          if (_sosConcurrentExtended) {
            await _startExtendedDiscoveryLocked(discovery);
          } else {
            await _startDiscoveryLocked(discovery);
          }
        });
        await onRestored?.call();
        await Future<void>.delayed(discoveryBurst);
      }
    } finally {
      if (_campaignGeneration == campaign) {
        await _advertisingLock.synchronized(() async {
          if (_campaignGeneration != campaign) return;
          if (_sosConcurrentExtended) {
            await _startExtendedDiscoveryLocked(discovery);
          } else {
            await _startDiscoveryLocked(discovery);
          }
        });
        await onRestored?.call();
      }
      if (_campaignGeneration == campaign) {
        _sosCampaignActive = false;
      }
    }
  }

  static Future<void> _startSosLocked(MeshSosAdvertisement alert) async {
    final payload = MeshGatt.manufacturerPayload(
      MeshGatt.sosPayloadType,
      alert.encode(),
    );
    if (_advertisingTier == 'legacy_1m+coded_extended' &&
        _activeMetadata != null) {
      try {
        await _startExtendedPayloadLocked(payload);
        _sosConcurrentExtended = true;
        return;
      } catch (error) {
        _extendedFallbackReason = 'SOS extended set unavailable: $error';
        _sosConcurrentExtended = false;
      }
    }
    _sosConcurrentExtended = false;
    await _ensureIdleLocked();
    await UniversalBlePeripheral.startAdvertising(
      services: const [MeshGatt.service],
      manufacturerData: ManufacturerData(MeshGatt.manufacturerId, payload),
      platformConfig: PeripheralPlatformConfig(
        android: PeripheralAndroidOptions(
          addManufacturerDataInScanResponse: false,
          addServicesInScanResponse: true,
          includeTxPowerLevel: BleAdvertisingBudget.fits(
            manufacturerPayloadBytes: payload.length,
            includeTxPower: true,
          ),
        ),
      ),
    );
    final state = await _waitForAdvertising();
    if (state != PeripheralAdvertisingState.advertising) {
      throw StateError('SOS advertising state is ${state.name}');
    }
  }

  static Future<void> _startExtendedPayloadLocked(Uint8List payload) async {
    await UniversalBlePeripheral.startExtendedAdvertising(
      services: const [MeshGatt.service],
      manufacturerData: ManufacturerData(MeshGatt.manufacturerId, payload),
      platformConfig: PeripheralPlatformConfig(
        android: PeripheralAndroidOptions(includeTxPowerLevel: true),
      ),
    );
    _capabilities = await UniversalBlePeripheral.getCapabilities();
  }

  static Future<void> _startExtendedDiscoveryLocked(
    DiscoveryMetadata metadata,
  ) async {
    final payload = MeshGatt.manufacturerPayload(
      MeshGatt.discoveryPayloadType,
      metadata.encode(),
    );
    await _startExtendedPayloadLocked(payload);
    _advertisingTier = 'legacy_1m+coded_extended';
  }
}

class DiscoveredPeer {
  const DiscoveredPeer({required this.device, required this.metadata});

  final BleDevice device;
  final DiscoveryMetadata metadata;
}

class MeshScanReport {
  const MeshScanReport({
    required this.peers,
    required this.beacons,
    required this.devicesSeen,
    required this.serviceMatches,
    required this.manufacturerMatches,
    required this.malformedMetadata,
    required this.fingerprintMismatches,
    this.uuidOnlyDeviceIds = const [],
  });

  final List<DiscoveredPeer> peers;
  final List<BeaconObservation> beacons;
  final int devicesSeen;
  final int serviceMatches;
  final int manufacturerMatches;
  final int malformedMetadata;
  final int fingerprintMismatches;

  /// Device IDs that matched the MeshSetu service UUID but never produced a
  /// decodable discovery record during this scan window (Bible audit
  /// Task 4). Some OEM BLE stacks fail to deliver or merge the scan-response
  /// packet that carries [DiscoveryMetadata], so `serviceMatches > 0` while
  /// `manufacturerMatches == 0` for that device — normal discovery then
  /// finds zero peers with no fallback. [MeshEventController] uses this list
  /// as a last-resort connection candidate set after repeated blind cycles,
  /// relying on the post-connection HELLO handshake (not this scan) to
  /// establish site identity, since no fingerprint is available here.
  final List<String> uuidOnlyDeviceIds;
}

abstract final class MeshScanner {
  static Future<List<DiscoveredPeer>> scan({
    Duration window = const Duration(seconds: 4),
    int? expectedFingerprint,
    Future<void>? cancel,
  }) async => (await scanReport(
    window: window,
    expectedFingerprint: expectedFingerprint,
    cancel: cancel,
  )).peers;

  static Future<MeshScanReport> scanReport({
    Duration window = const Duration(seconds: 4),
    int? expectedFingerprint,
    Future<void>? cancel,
    void Function(MeshSosAdvertisement alert, String deviceId)? onSosAlert,
  }) async {
    final found = <String, DiscoveredPeer>{};
    final devicesSeen = <String>{};
    final serviceMatches = <String>{};
    final manufacturerMatches = <String>{};
    final malformedMetadata = <String>{};
    final fingerprintMismatches = <String>{};
    final discoveryRecordSeen = <String>{};
    final beacons = <String, BeaconObservation>{};
    StreamSubscription<BleDevice>? subscription;
    var started = false;
    try {
      subscription = UniversalBle.scanStream.listen((device) {
        devicesSeen.add(device.deviceId);
        if (device.services.any(
          (service) => service.toLowerCase() == MeshGatt.service,
        )) {
          serviceMatches.add(device.deviceId);
        }
        for (final data in device.manufacturerDataList) {
          if (data.companyId != MeshGatt.manufacturerId) continue;
          final sosPayload = MeshGatt.payloadForType(
            data.payload,
            MeshGatt.sosPayloadType,
          );
          if (sosPayload != null) {
            final alert = MeshSosAdvertisement.decode(sosPayload);
            if (alert != null &&
                (expectedFingerprint == null ||
                    alert.siteFingerprint ==
                        (expectedFingerprint & 0xffffffff))) {
              onSosAlert?.call(alert, device.deviceId);
            }
            continue;
          }
          final beaconPayload = MeshGatt.payloadForType(
            data.payload,
            MeshGatt.beaconPayloadType,
          );
          if (beaconPayload != null) {
            final metadata = BeaconMetadata.decode(beaconPayload);
            if (metadata != null) {
              final observation = BeaconObservation(
                anchorId: metadata.anchorId,
                rssi: device.rssi ?? -128,
                observedAtMs: DateTime.now().millisecondsSinceEpoch,
              );
              final previous = beacons[metadata.anchorId];
              if (previous == null || observation.rssi > previous.rssi) {
                beacons[metadata.anchorId] = observation;
              }
            }
            continue;
          }
          final discoveryPayload = MeshGatt.payloadForType(
            data.payload,
            MeshGatt.discoveryPayloadType,
          );
          if (discoveryPayload == null) continue;
          manufacturerMatches.add(device.deviceId);
          discoveryRecordSeen.add(device.deviceId);
          final metadata = DiscoveryMetadata.decode(discoveryPayload);
          if (metadata == null) {
            malformedMetadata.add(device.deviceId);
            continue;
          }
          if (expectedFingerprint != null &&
              metadata.fingerprint != expectedFingerprint) {
            fingerprintMismatches.add(device.deviceId);
            continue;
          }
          found[device.deviceId] = DiscoveredPeer(
            device: device,
            metadata: metadata,
          );
        }
      });
      await UniversalBle.startScan(
        // Some Android devices expose the service UUID and manufacturer data
        // in different advertisement/scan-response packets. A native service
        // filter can discard the device before Dart receives the packet that
        // contains our discovery metadata, so filtering is done above.
        scanFilter: ScanFilter(),
        platformConfig: PlatformConfig(
          android: AndroidOptions(scanMode: AndroidScanMode.lowLatency),
        ),
      );
      started = true;
      final timeout = Future<void>.delayed(window);
      if (cancel == null) {
        await timeout;
      } else {
        await Future.any<void>([timeout, cancel]);
      }
    } finally {
      if (started) {
        try {
          await UniversalBle.stopScan();
        } catch (_) {
          // Preserve the original scan failure while still releasing the
          // subscription below.
        }
      }
      await subscription?.cancel();
    }
    return MeshScanReport(
      peers: found.values.toList(growable: false),
      beacons: beacons.values.toList(growable: false),
      devicesSeen: devicesSeen.length,
      serviceMatches: serviceMatches.length,
      manufacturerMatches: manufacturerMatches.length,
      malformedMetadata: malformedMetadata.length,
      fingerprintMismatches: fingerprintMismatches.length,
      uuidOnlyDeviceIds: serviceMatches
          .difference(discoveryRecordSeen)
          .toList(growable: false),
    );
  }
}

abstract final class MeshBeaconScanner {
  static Future<List<BeaconObservation>> scan({
    Duration window = const Duration(seconds: 2),
    Future<void>? cancel,
  }) async {
    final found = <String, BeaconObservation>{};
    StreamSubscription<BleDevice>? subscription;
    var started = false;
    try {
      subscription = UniversalBle.scanStream.listen((device) {
        for (final data in device.manufacturerDataList) {
          if (data.companyId != MeshGatt.manufacturerId) continue;
          final payload = MeshGatt.payloadForType(
            data.payload,
            MeshGatt.beaconPayloadType,
          );
          if (payload == null) continue;
          final metadata = BeaconMetadata.decode(payload);
          if (metadata == null) continue;
          final observation = BeaconObservation(
            anchorId: metadata.anchorId,
            rssi: device.rssi ?? -128,
            observedAtMs: DateTime.now().millisecondsSinceEpoch,
          );
          final previous = found[metadata.anchorId];
          if (previous == null || observation.rssi > previous.rssi) {
            found[metadata.anchorId] = observation;
          }
        }
      });
      await UniversalBle.startScan(
        scanFilter: ScanFilter(),
        platformConfig: PlatformConfig(
          android: AndroidOptions(scanMode: AndroidScanMode.lowLatency),
        ),
      );
      started = true;
      final timeout = Future<void>.delayed(window);
      await (cancel == null ? timeout : Future.any<void>([timeout, cancel]));
    } finally {
      if (started) {
        try {
          await UniversalBle.stopScan();
        } catch (_) {
          // Preserve the original scan failure while releasing the stream.
        }
      }
      await subscription?.cancel();
    }
    return found.values.toList(growable: false);
  }
}
