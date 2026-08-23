/// Bluetooth LE advertising-data budget helpers.
///
/// Each AD structure consumes one length byte and one type byte in addition
/// to its value. Legacy advertising and scan responses are each capped at 31
/// bytes; extended advertising uses the controller-reported limit.
abstract final class BleAdvertisingBudget {
  static const int legacyLimit = 31;
  static const int flagsBytes = 3; // length + type + one flags byte
  static const int txPowerBytes = 3; // length + type + one signed dBm byte
  static const int serviceUuid128Bytes = 18; // length + type + 16-byte UUID

  static int manufacturerDataBytes(int payloadBytes) =>
      2 + 2 + payloadBytes; // length/type + company identifier + payload

  static int totalBytes({
    required int manufacturerPayloadBytes,
    bool includeFlags = true,
    bool includeTxPower = false,
    int serviceUuid128Count = 0,
  }) {
    if (manufacturerPayloadBytes < 0) {
      throw ArgumentError.value(
        manufacturerPayloadBytes,
        'manufacturerPayloadBytes',
        'must not be negative',
      );
    }
    if (serviceUuid128Count < 0) {
      throw ArgumentError.value(
        serviceUuid128Count,
        'serviceUuid128Count',
        'must not be negative',
      );
    }
    return (includeFlags ? flagsBytes : 0) +
        manufacturerDataBytes(manufacturerPayloadBytes) +
        (includeTxPower ? txPowerBytes : 0) +
        (serviceUuid128Bytes * serviceUuid128Count);
  }

  static bool fits({
    required int manufacturerPayloadBytes,
    int limit = legacyLimit,
    bool includeFlags = true,
    bool includeTxPower = false,
    int serviceUuid128Count = 0,
  }) =>
      totalBytes(
        manufacturerPayloadBytes: manufacturerPayloadBytes,
        includeFlags: includeFlags,
        includeTxPower: includeTxPower,
        serviceUuid128Count: serviceUuid128Count,
      ) <=
      limit;

  static void requireFits({
    required int manufacturerPayloadBytes,
    int limit = legacyLimit,
    bool includeFlags = true,
    bool includeTxPower = false,
    int serviceUuid128Count = 0,
    String label = 'BLE advertisement',
  }) {
    final used = totalBytes(
      manufacturerPayloadBytes: manufacturerPayloadBytes,
      includeFlags: includeFlags,
      includeTxPower: includeTxPower,
      serviceUuid128Count: serviceUuid128Count,
    );
    if (used > limit) {
      throw StateError('$label needs $used bytes, but the limit is $limit');
    }
  }
}
