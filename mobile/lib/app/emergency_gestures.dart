import 'dart:async';

import 'package:flutter/services.dart';

import '../core/ble/sos_advertisement.dart';

/// Android accessibility-service gesture vocabulary. These values intentionally
/// map only to the typed, structured red-SOS pipeline; they never request the
/// separate CEAL identity/UID compact SOS flow.
enum EmergencyGesture { normal, fire, crime, kidnap, medical, naturalDisaster }

extension EmergencyGestureDetails on EmergencyGesture {
  String get nativeName => switch (this) {
    EmergencyGesture.normal => 'normal',
    EmergencyGesture.fire => 'fire',
    EmergencyGesture.crime => 'crime',
    EmergencyGesture.kidnap => 'kidnap',
    EmergencyGesture.medical => 'medical',
    EmergencyGesture.naturalDisaster => 'natural_disaster',
  };

  String get label => switch (this) {
    EmergencyGesture.normal => 'General',
    EmergencyGesture.fire => 'Fire',
    EmergencyGesture.crime => 'Crime',
    EmergencyGesture.kidnap => 'Kidnap',
    EmergencyGesture.medical => 'Medical',
    EmergencyGesture.naturalDisaster => 'Natural disaster',
  };
}

const defaultEmergencyGestureMappings = <EmergencyGesture, String>{
  EmergencyGesture.normal: 'UU',
  EmergencyGesture.fire: 'DDD',
  EmergencyGesture.crime: 'UDU',
  EmergencyGesture.kidnap: 'DUD',
  EmergencyGesture.medical: 'UUU',
  EmergencyGesture.naturalDisaster: 'DDDD',
};

/// Returns a user-facing validation message, or null for a complete and safe
/// configuration. Patterns use U (volume up) and D (volume down).
String? validateEmergencyGestureMappings(
  Map<EmergencyGesture, String> mappings,
) {
  if (mappings.length != EmergencyGesture.values.length ||
      !EmergencyGesture.values.every(mappings.containsKey)) {
    return 'Set a gesture for every emergency type.';
  }
  final patterns = <String>{};
  for (final gesture in EmergencyGesture.values) {
    final pattern = mappings[gesture] ?? '';
    if (!RegExp(r'^[UD]{2,5}$').hasMatch(pattern)) {
      return '${gesture.label} must use 2–5 Volume up or Volume down presses.';
    }
    if (!patterns.add(pattern)) {
      return 'Each emergency type needs a different button sequence.';
    }
  }
  return null;
}

SosEmergencyType? emergencyTypeForGesture(Object? value) => switch (value) {
  'normal' || 'general' => SosEmergencyType.general,
  'fire' => SosEmergencyType.fire,
  'crime' => SosEmergencyType.crime,
  'kidnap' => SosEmergencyType.kidnap,
  'medical' => SosEmergencyType.medical,
  'natural_disaster' => SosEmergencyType.naturalDisaster,
  _ => null,
};

abstract final class EmergencyGestureSettings {
  static const _channel = MethodChannel('meshsetu/emergency-gestures');
  static final _typedSosGestures =
      StreamController<SosEmergencyType>.broadcast();
  static var _isListeningForTypedSosGestures = false;

  /// Typed red-SOS confirmations requested by Android's Accessibility Service.
  /// These values deliberately cannot represent CEAL identity SOS events.
  static Stream<SosEmergencyType> get typedSosGestures =>
      _typedSosGestures.stream;

  /// Installs the UI-engine receiver before asking Android to deliver a pending
  /// gesture. The Android side retains a gesture until this receiver is ready,
  /// which covers both a cold Activity launch and a warm `onNewIntent` launch.
  static void startListeningForTypedSosGestures() {
    if (_isListeningForTypedSosGestures) return;
    _isListeningForTypedSosGestures = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'typedSosGesture') return;
      final emergencyType = emergencyTypeForGesture(call.arguments);
      if (emergencyType != null) _typedSosGestures.add(emergencyType);
    });
    unawaited(_channel.invokeMethod<void>('gestureListenerReady'));
  }

  /// Retrieves a gesture persisted by Android before Flutter's UI receiver was
  /// ready. `take` semantics ensure it cannot generate a second SOS.
  static Future<SosEmergencyType?> takePendingTypedSosGesture() async =>
      emergencyTypeForGesture(
        await _channel.invokeMethod<Object?>('takePendingTypedSosGesture'),
      );

  static Future<bool> isEnabled() async =>
      await _channel.invokeMethod<bool>('isEnabled') ?? false;

  static Future<void> openSettings() => _channel.invokeMethod('openSettings');

  static Future<Map<EmergencyGesture, String>> loadMappings() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getGestureMappings',
    );
    if (raw == null) return defaultEmergencyGestureMappings;
    return {
      for (final gesture in EmergencyGesture.values)
        gesture:
            (raw[gesture.nativeName] as String?) ??
            defaultEmergencyGestureMappings[gesture]!,
    };
  }

  static Future<void> saveMappings(
    Map<EmergencyGesture, String> mappings,
  ) async {
    final error = validateEmergencyGestureMappings(mappings);
    if (error != null) throw ArgumentError(error);
    await _channel.invokeMethod<void>('saveGestureMappings', {
      for (final entry in mappings.entries) entry.key.nativeName: entry.value,
    });
  }

  static Future<void> resetMappings() async {
    await _channel.invokeMethod<void>('resetGestureMappings');
  }
}
