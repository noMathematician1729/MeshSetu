import 'package:meshsetu_mobile/core/ble/device_sms_service.dart';
import 'package:test/test.dart';

void main() {
  test('resolved relay alert matches the required CEAL SMS format', () {
    final body = DeviceSmsService.buildRelayAlertBody(
      victimName: 'Vedant',
      victimPhone: '+919004481876',
      bloodGroup: 'AB+',
      allergies: 'none',
      conditions: 'none',
      relayLatitude: 19.0729872,
      relayLongitude: 72.8998389,
      reporterUid: 'd7c804a96f05',
      sequence: 1,
      at: DateTime.utc(2026, 2, 28, 23, 20, 21, 973),
    );

    expect(body, '''
EMERGENCY SOS — CEAL
Victim: Vedant
Phone: +919004481876
Blood group: AB+
Allergies: none
Conditions: none
Relayer location: 19.07299, 72.89984
https://maps.google.com/?q=19.0729872,72.8998389
Time: 2026-02-28T23:20:21.973Z
ID: uid:d7c804a96f05:1''');
  });

  test('the detailed alert is never truncated to one SMS segment', () {
    final body = DeviceSmsService.buildRelayAlertBody(
      victimName: 'Vedant',
      victimPhone: '+919004481876',
      bloodGroup: 'AB+',
      allergies: 'none',
      conditions: 'none',
      relayLatitude: 19.0729872,
      relayLongitude: 72.8998389,
      reporterUid: 'd7c804a96f05',
      sequence: 1,
    );

    // Android splits long bodies with divideMessage; cutting at 160 here would
    // destroy the map link and the incident ID.
    expect(body.length, greaterThan(160));
    expect(body, endsWith('ID: uid:d7c804a96f05:1'));
  });

  test('missing identity and medical fields fall back, never blank', () {
    final body = DeviceSmsService.buildRelayAlertBody(
      victimName: '',
      victimPhone: '   ',
      bloodGroup: null,
      allergies: '',
      conditions: null,
      relayLatitude: 1.5,
      relayLongitude: 2.5,
      reporterUid: 'abc123abc123',
      sequence: 9,
      at: DateTime.utc(2026, 1, 1),
    );

    expect(body, contains('Victim: Unknown'));
    expect(body, contains('Phone: Unknown'));
    expect(body, contains('Blood group: Unknown'));
    expect(body, contains('Allergies: none'));
    expect(body, contains('Conditions: none'));
    expect(body, contains('ID: uid:abc123abc123:9'));
  });

  test('a denied GPS still sends medical detail without a map link', () {
    final body = DeviceSmsService.buildRelayAlertBody(
      victimName: 'Asha',
      victimPhone: '+911234567890',
      bloodGroup: 'O+',
      allergies: 'penicillin',
      conditions: 'asthma',
      reporterUid: 'aabbccddeeff',
      sequence: 3,
      at: DateTime.utc(2026, 3, 1, 10, 30),
    );

    expect(body, contains('Relayer location: unavailable'));
    expect(body, isNot(contains('maps.google.com')));
    expect(body, contains('Allergies: penicillin'));
    expect(body, contains('Conditions: asthma'));
    expect(body, contains('Time: 2026-03-01T10:30:00.000Z'));
  });

  test('the existing compact fallback body is left unchanged', () {
    // The offline path must keep working exactly as it does today.
    final body = DeviceSmsService.buildBody(
      reporterName: 'Unknown — nearby SOS',
      emergencyType: 'general',
    );

    expect(
      body,
      'EMERGENCY: Unknown — nearby SOS needs help.\n'
      'Type: general\n'
      'Call 112.',
    );
  });
}
