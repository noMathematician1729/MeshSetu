import 'package:universal_ble/universal_ble.dart';

enum MeshAdvertisingTier { legacy1m, legacy1mCodedExtended }

class MeshAdvertisingTierDecision {
  const MeshAdvertisingTierDecision(this.tier, {this.reason});

  final MeshAdvertisingTier tier;
  final String? reason;

  bool get usesExtended => tier == MeshAdvertisingTier.legacy1mCodedExtended;
}

/// Selects only from runtime-reported capabilities. No device model, OEM, or
/// Android release identity is part of this policy.
abstract final class MeshAdvertisingTierPolicy {
  static MeshAdvertisingTierDecision select(
    BlePeripheralCapabilities capabilities,
  ) {
    if (capabilities.supportsExtendedAdvertising &&
        capabilities.supportsCodedPhy &&
        capabilities.supportsMultipleAdvertisement) {
      return const MeshAdvertisingTierDecision(
        MeshAdvertisingTier.legacy1mCodedExtended,
      );
    }
    if (capabilities.supportsExtendedAdvertising) {
      final missing = <String>[
        if (!capabilities.supportsCodedPhy) 'coded_phy',
        if (!capabilities.supportsMultipleAdvertisement) 'multiple_advertiser',
      ];
      return MeshAdvertisingTierDecision(
        MeshAdvertisingTier.legacy1m,
        reason: 'extended_fallback_missing=${missing.join("+")}',
      );
    }
    return const MeshAdvertisingTierDecision(
      MeshAdvertisingTier.legacy1m,
      reason: 'extended_advertising_unsupported',
    );
  }
}
