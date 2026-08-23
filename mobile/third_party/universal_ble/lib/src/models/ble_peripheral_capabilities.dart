class BlePeripheralCapabilities {
  final bool supportsPeripheralMode;
  final bool supportsManufacturerDataInAdvertisement;
  final bool supportsManufacturerDataInScanResponse;
  final bool supportsServiceDataInAdvertisement;
  final bool supportsServiceDataInScanResponse;
  final bool supportsTargetedCharacteristicUpdate;
  final bool supportsAdvertisingTimeout;

  /// Runtime Android controller capabilities. These are false/unknown on
  /// platforms that do not expose the corresponding radio feature.
  final bool supportsExtendedAdvertising;
  final bool supportsCodedPhy;
  final bool supports2MPhy;
  final bool supportsMultipleAdvertisement;
  final int? maximumAdvertisingDataLength;

  /// The last TX power the Android stack reported in its start callback.
  /// This is not the requested value and may be lower on OEM hardware.
  final int? effectiveTxPowerLevel;
  final int? effectiveExtendedTxPowerLevel;
  final bool extendedAdvertisingActive;
  final String advertisingTier;

  const BlePeripheralCapabilities({
    required this.supportsPeripheralMode,
    required this.supportsManufacturerDataInAdvertisement,
    required this.supportsManufacturerDataInScanResponse,
    required this.supportsServiceDataInAdvertisement,
    required this.supportsServiceDataInScanResponse,
    required this.supportsTargetedCharacteristicUpdate,
    required this.supportsAdvertisingTimeout,
    this.supportsExtendedAdvertising = false,
    this.supportsCodedPhy = false,
    this.supports2MPhy = false,
    this.supportsMultipleAdvertisement = false,
    this.maximumAdvertisingDataLength,
    this.effectiveTxPowerLevel,
    this.effectiveExtendedTxPowerLevel,
    this.extendedAdvertisingActive = false,
    this.advertisingTier = 'legacy_1m',
  });
}
