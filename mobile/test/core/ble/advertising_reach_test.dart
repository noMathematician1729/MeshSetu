import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/mesh_bridge_client.dart';
import 'package:meshsetu_mobile/core/ble/advertising_budget.dart';
import 'package:meshsetu_mobile/core/ble/advertising_tier.dart';
import 'package:universal_ble/universal_ble.dart';

BlePeripheralCapabilities _capabilities({
  bool extended = false,
  bool coded = false,
  bool multiple = false,
}) => BlePeripheralCapabilities(
  supportsPeripheralMode: true,
  supportsManufacturerDataInAdvertisement: true,
  supportsManufacturerDataInScanResponse: true,
  supportsServiceDataInAdvertisement: false,
  supportsServiceDataInScanResponse: false,
  supportsTargetedCharacteristicUpdate: true,
  supportsAdvertisingTimeout: true,
  supportsExtendedAdvertising: extended,
  supportsCodedPhy: coded,
  supportsMultipleAdvertisement: multiple,
);

void main() {
  group('BleAdvertisingBudget', () {
    test('calculates the exact 31-byte SOS-with-TX-power legacy budget', () {
      // type byte + 20-byte v2 alert = 21 bytes of manufacturer payload.
      expect(
        BleAdvertisingBudget.totalBytes(
          manufacturerPayloadBytes: 21,
          includeTxPower: true,
        ),
        31,
      );
      expect(
        BleAdvertisingBudget.fits(
          manufacturerPayloadBytes: 21,
          includeTxPower: true,
        ),
        isTrue,
      );
    });

    test('rejects a payload beyond the legacy budget', () {
      expect(
        BleAdvertisingBudget.fits(
          manufacturerPayloadBytes: 22,
          includeTxPower: true,
        ),
        isFalse,
      );
      expect(
        () => BleAdvertisingBudget.requireFits(
          manufacturerPayloadBytes: 22,
          includeTxPower: true,
        ),
        throwsStateError,
      );
    });

    test('accepts the same data against a runtime extended limit', () {
      expect(
        BleAdvertisingBudget.fits(
          manufacturerPayloadBytes: 200,
          includeTxPower: true,
          limit: 1650,
        ),
        isTrue,
      );
    });
  });

  group('MeshAdvertisingTierPolicy', () {
    test('selects legacy when every enhanced capability is false', () {
      final decision = MeshAdvertisingTierPolicy.select(_capabilities());
      expect(decision.tier, MeshAdvertisingTier.legacy1m);
      expect(decision.usesExtended, isFalse);
    });

    test('selects legacy when coded PHY is missing', () {
      final decision = MeshAdvertisingTierPolicy.select(
        _capabilities(extended: true, multiple: true),
      );
      expect(decision.tier, MeshAdvertisingTier.legacy1m);
      expect(decision.reason, contains('coded_phy'));
    });

    test(
      'selects the additive coded tier only when all runtime gates pass',
      () {
        final decision = MeshAdvertisingTierPolicy.select(
          _capabilities(extended: true, coded: true, multiple: true),
        );
        expect(decision.tier, MeshAdvertisingTier.legacy1mCodedExtended);
        expect(decision.usesExtended, isTrue);
        expect(decision.reason, isNull);
      },
    );
  });

  group('MeshPeerSnapshot distance calibration', () {
    test('uses the reported one-meter TX power when present', () {
      const peer = MeshPeerSnapshot(
        peerId: 'peer',
        connected: false,
        rssi: -59,
        txPowerAtOneMeter: -49,
        lastSeenMs: 0,
      );
      expect(peer.estimatedDistanceMeters, closeTo(math.pow(10, .4), 0.0001));
    });

    test('retains the historical calibration for peers without TX power', () {
      const peer = MeshPeerSnapshot(
        peerId: 'peer',
        connected: false,
        rssi: -59,
        lastSeenMs: 0,
      );
      expect(peer.estimatedDistanceMeters, closeTo(1, 0.0001));
    });
  });
}
