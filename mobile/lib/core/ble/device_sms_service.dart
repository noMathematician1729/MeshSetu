import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sends SMS directly from the device's own SIM card to emergency contacts
/// using Android's [SmsManager] API through the native method channel
/// `meshsetu/device-sms`.
///
/// This is the preferred emergency path when internet is unavailable:
/// - No API key, billing account, or internet connection required.
/// - Uses the local carrier, so delivery to Indian +91 numbers is guaranteed
///   without any Twilio/Fast2SMS international restriction.
/// - Permission [android.permission.SEND_SMS] must be granted at runtime
///   before calling [sendToAll]; [BlePermissions] requests it at startup.
///
/// iOS note: auto-SMS is not supported on iOS (SmsManager is Android-only).
/// The channel call is silently skipped on non-Android platforms.
abstract final class DeviceSmsService {
  static const _channel = MethodChannel('meshsetu/device-sms');

  /// Builds the SMS body from a received SOS alert.
  ///
  /// Plain ASCII, no emoji, single GSM-7 segment (≤160 chars) — mirrors the
  /// `Ceal/backend/src/services/twilio.ts` format that is proven to deliver
  /// on Indian carriers without content filtering.
  static String buildBody({
    required String reporterName,
    double? latitude,
    double? longitude,
    String? emergencyType,
  }) {
    final hasLocation = latitude != null && longitude != null;
    final coords = hasLocation
        ? '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}'
        : null;
    final mapsUrl =
        coords != null ? 'https://maps.google.com/?q=$coords' : null;

    final parts = <String>[
      'EMERGENCY: $reporterName needs help.',
      if (emergencyType != null && emergencyType.isNotEmpty)
        'Type: $emergencyType',
      if (coords != null) coords,
      if (mapsUrl != null) mapsUrl,
      'Call 112.',
    ];

    // Enforce a single GSM-7 segment to avoid multi-part carrier filtering.
    final body = parts.join('\n');
    return body.length <= 160 ? body : body.substring(0, 160);
  }

  /// Sends [message] to each phone number in [phones] using the device SIM.
  ///
  /// Returns the count of numbers that were accepted by the platform.
  /// A number can only be sent on Android; non-Android platforms return 0.
  /// Individual send failures are logged but do not throw — emergency delivery
  /// must not stop partway through a contact list.
  static Future<int> sendToAll(
    List<String> phones,
    String message,
  ) async {
    if (!defaultTargetPlatform
        .toString()
        .contains('TargetPlatform.android')) {
      // SmsManager is Android-only. On other platforms skip silently.
      return 0;
    }
    int sent = 0;
    for (final phone in phones) {
      if (phone.trim().isEmpty) continue;
      try {
        final ok = await _channel.invokeMethod<bool>('sendSms', {
              'phone': phone.trim(),
              'message': message,
            }) ??
            false;
        if (ok) sent++;
      } on PlatformException catch (e) {
        debugPrint(
          '[DeviceSmsService] SMS to ***${phone.length > 4 ? phone.substring(phone.length - 4) : phone} '
          'failed: ${e.message}',
        );
      } catch (e) {
        debugPrint('[DeviceSmsService] SMS unexpected error: $e');
      }
    }
    return sent;
  }
}
