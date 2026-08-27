import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/model/model.dart';
import '../sos/sos_payload.dart';
import '../voice/voice_repository.dart';

final class GatewayResponseCommand {
  const GatewayResponseCommand({
    required this.responseId,
    required this.replyToEventId,
    required this.siteId,
    required this.destinationEphemeralId,
    required this.signedPayload,
    required this.createdAtMs,
    required this.expiresAtMs,
  });

  final String responseId;
  final String replyToEventId;
  final String siteId;
  final int destinationEphemeralId;
  final List<int> signedPayload;
  final int createdAtMs;
  final int expiresAtMs;

  factory GatewayResponseCommand.fromJson(Map<String, Object?> json) {
    int integer(String key) {
      final value = json[key];
      if (value is num) return value.toInt();
      return int.parse('$value');
    }

    final encoded = json['signed_payload_b64'];
    if (encoded is! String || encoded.isEmpty) {
      throw const FormatException('gateway command has no signed payload');
    }
    return GatewayResponseCommand(
      responseId: json['response_id'] as String,
      replyToEventId: json['event_id'] as String,
      siteId: json['site_id'] as String,
      destinationEphemeralId: integer('destination_ephemeral_id'),
      signedPayload: base64Decode(encoded),
      createdAtMs: integer('created_at_ms'),
      expiresAtMs: integer('expires_at_ms'),
    );
  }
}

/// Bible §15.1/§3.4: the gateway phone receives mesh objects exactly like
/// any other peer (Dev A's `MeshTransportCoordinator`); this bridge only
/// pushes the original encrypted/reassembled mesh object to the configured
/// dashboard URL over local Wi-Fi. The Node backend independently verifies
/// and decrypts the packet; the gateway never supplies trusted SOS fields.
class GatewayBridge {
  GatewayBridge({
    required this.baseUrl,
    required this.demoKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri baseUrl;
  final String demoKey;

  /// Injectable so delivery/retry behavior can be tested without a network.
  final http.Client _client;

  /// Emergency uploads run against a control room that may be cold-starting
  /// (free hosting tiers spin down after idle periods and can take ~30 s to
  /// answer the first request). A 12-second budget silently failed every
  /// first SOS after an idle period, so allow a full cold start.
  static const Duration requestTimeout = Duration(seconds: 45);

  Future<void> postToDashboard(Map<String, Object?> event) async {
    final uri = baseUrl.resolve('/api/events');
    final response = await _client
        .post(
          uri,
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-demo-key': demoKey,
          },
          body: jsonEncode(event),
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('dashboard HTTP ${response.statusCode}');
    }
  }

  /// Plaintext SOS upload for the phone that authored the alert.
  ///
  /// The encrypted [postEncryptedObject] path stays the preferred, verifiable
  /// route. This one exists because the origin device already holds the
  /// decoded payload: when it has internet, the control room must receive the
  /// emergency even if the mesh never found a peer to take custody. The
  /// server upserts by `event_id`, so retries and a later encrypted delivery
  /// converge on a single incident rather than duplicating it.
  Future<void> postRelaySos({
    required Map<String, Object?> event,
    String? relayDeviceId,
  }) async {
    final response = await _client
        .post(
          baseUrl.resolve('/v1/gateway/relay-sos'),
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-gateway-key': demoKey,
          },
          body: jsonEncode({
            'event': event,
            if (relayDeviceId != null) 'relay_device_id': relayDeviceId,
          }),
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'relay SOS HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Bible §15.4 dashboard fields for an SOS this device authored, built
  /// from the durable outbox row rather than a reassembled mesh envelope.
  Map<String, Object?> originEventJson({
    required String eventId,
    required int objectId,
    required String siteId,
    required String roomId,
    required StructuredSosPayload sos,
    required int createdAtMs,
    required int expiresAtMs,
  }) => {
    'event_id': eventId,
    'object_id': objectId.toString(),
    'site_id': siteId,
    'room_id': roomId,
    'priority': sos.triagePriority.name,
    'incident_type': sos.incidentType,
    'transcript': sos.transcript.isEmpty ? null : sos.transcript,
    'zone': sos.logicalZone.isEmpty ? null : sos.logicalZone,
    'latitude': sos.latitude,
    'longitude': sos.longitude,
    'accuracy_m': sos.accuracyM,
    'location_captured_at_ms': sos.locationCapturedAtMs,
    'hops': 0,
    'relay_latency_ms': 0,
    'created_at_ms': createdAtMs,
    'expires_at_ms': expiresAtMs,
    'reporter_uid': sos.reporter?.reporterUid,
  };

  Future<void> postEncryptedObject({
    required String siteId,
    required int objectId,
    required List<int> packet,
    required int receivedAtMs,
    String? peerId,
  }) async {
    final response = await _client
        .post(
          baseUrl.resolve('/v1/gateway/objects'),
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-gateway-key': demoKey,
          },
          body: jsonEncode({
            'site_id': siteId,
            'object_id': objectId.toString(),
            'packet_b64': base64Encode(packet),
            'received_at_ms': receivedAtMs,
            'peer_id': peerId,
          }),
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('dashboard packet HTTP ${response.statusCode}');
    }
  }

  /// Bible §15.4 dashboard fields, built from a reassembled envelope +
  /// its decoded [StructuredSosPayload].
  Map<String, Object?> eventJson({
    required MeshEnvelope envelope,
    required StructuredSosPayload sos,
    int? relayLatencyMs,
  }) => {
    'event_id': envelope.eventId,
    'object_id': envelope.objectId.toString(),
    'site_id': envelope.siteId,
    'room_id': envelope.roomId,
    'priority': sos.triagePriority.name,
    'incident_type': sos.incidentType,
    'transcript': sos.transcript.isEmpty ? null : sos.transcript,
    'zone': sos.logicalZone.isEmpty ? null : sos.logicalZone,
    'latitude': sos.latitude,
    'longitude': sos.longitude,
    'accuracy_m': sos.accuracyM,
    'location_captured_at_ms': sos.locationCapturedAtMs,
    'hops': envelope.hopCount,
    'relay_latency_ms': relayLatencyMs,
    'voice_clip_id': sos.voiceClipId.isEmpty ? null : sos.voiceClipId,
    'audio_state': sos.voiceClipId.isEmpty ? null : 'queued',
    'reporter_uid': sos.reporter?.reporterUid,
    'reporter_name': sos.reporter?.name,
    'reporter_phone': sos.reporter?.phone,
    'reporter_language': sos.reporter?.language,
    'reporter_blood_group': sos.reporter?.bloodGroup,
    'reporter_primary_contact': sos.reporter == null
        ? null
        : '${sos.reporter!.primaryContactName} (${sos.reporter!.primaryContactPhone})',
  };

  Map<String, Object?> voiceCompleteJson(VoiceObjectPayload voice) => {
    'event_id': voice.sosEventId,
    'priority': 'unknown',
    'incident_type': 'unknown',
    'voice_clip_id': voice.clipId,
    'audio_state': 'complete',
  };

  Map<String, Object?> testSosJson(MeshEnvelope envelope) => {
    'event_id': envelope.eventId,
    'object_id': envelope.objectId.toString(),
    'site_id': envelope.siteId,
    'room_id': envelope.roomId,
    'priority': 'p0Critical',
    'incident_type': 'test_sos',
    'transcript': 'BLE SOS notification test',
    'hops': envelope.hopCount,
    'audio_state': 'n/a',
  };

  /// CEAL-style: register the onboarded user profile with the backend so
  /// UID→profile resolution works when only a compact BLE alert is received.
  Future<bool> registerProfile(Map<String, Object?> profile) async {
    try {
      final response = await _client
          .post(
            baseUrl.resolve('/v1/profiles'),
            headers: {
              'content-type': 'application/json',
              'x-meshsetu-gateway-key': demoKey,
            },
            body: jsonEncode(profile),
          )
          .timeout(requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// CEAL-style: forward a compact BLE SOS alert (UID-only) to the backend
  /// so it can resolve the reporter's profile and create an enriched event.
  ///
  /// The decoded response body is returned so a receiver with internet can
  /// show the resolved incident detail instead of a generic alert.
  Future<(bool, String, Map<String, Object?>?)> forwardCealSos({
    required String reporterUid,
    required String siteId,
    required int flags,
    int? originId,
    int? sequence,
    double? latitude,
    double? longitude,
    double? accuracyM,
    int? locationCapturedAtMs,
  }) async {
    try {
      final response = await _client
          .post(
            baseUrl.resolve('/v1/gateway/ceal-sos'),
            headers: {
              'content-type': 'application/json',
              'x-meshsetu-gateway-key': demoKey,
            },
            body: jsonEncode({
              'reporter_uid': reporterUid,
              'site_id': siteId,
              'flags': flags,
              'origin_id': originId,
              'sequence': sequence,
              'latitude': latitude,
              'longitude': longitude,
              'accuracy_m': accuracyM,
              'location_captured_at_ms': locationCapturedAtMs,
              'received_at_ms': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .timeout(requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return (
          true,
          'ok',
          decoded is Map ? decoded.cast<String, Object?>() : null,
        );
      }
      return (false, 'HTTP ${response.statusCode}: ${response.body}', null);
    } catch (error) {
      return (false, '$error', null);
    }
  }

  /// Fetches the incident record rendered by the dashboard for the native
  /// recipient detail screen. This public route is intentionally linked from
  /// SOS notifications and does not require operator credentials.
  Future<Map<String, Object?>?> fetchPublicIncident(String eventId) async {
    try {
      final response = await _client
          .get(
            baseUrl.resolve('/v1/public/sos/${Uri.encodeComponent(eventId)}'),
          )
          .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  Future<({String cursor, List<GatewayResponseCommand> commands})>
  pollAuthorityCommands({
    required String gatewaySessionId,
    required String cursor,
    int waitMs = 15000,
    int limit = 20,
  }) async {
    final query = Uri(
      queryParameters: {
        'cursor': cursor,
        'wait_ms': '$waitMs',
        'limit': '$limit',
      },
    ).query;
    final response = await _client
        .get(
          baseUrl.resolve(
            '/v1/gateways/${Uri.encodeComponent(gatewaySessionId)}/commands?$query',
          ),
          headers: {'x-meshsetu-gateway-key': demoKey},
        )
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('gateway command HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('invalid gateway command response');
    }
    final rawCommands = decoded['commands'];
    if (rawCommands is! List) {
      throw const FormatException('gateway command list is missing');
    }
    return (
      cursor: '${decoded['cursor'] ?? cursor}',
      commands: [
        for (final raw in rawCommands)
          if (raw is Map)
            GatewayResponseCommand.fromJson(raw.cast<String, Object?>()),
      ],
    );
  }

  /// Reports a bounded, additive lifecycle update for a signed authority
  /// response. Gateway custody is deliberately separate from sender delivery:
  /// SENDER_DELIVERED must carry the sender-generated receipt identity and the
  /// existing receipt endpoint remains the only path to the final dashboard
  /// state.
  Future<bool> reportAuthorityResponseProgress({
    required String responseId,
    required String gatewaySessionId,
    required String state,
    String? routeMode,
    int? returnHops,
    int? retryCount,
    String? error,
    String? receiptId,
    String? replyToEventId,
    int? senderEphemeralId,
  }) async {
    final response = await _client
        .post(
          baseUrl.resolve(
            '/v1/responses/${Uri.encodeComponent(responseId)}/progress',
          ),
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-gateway-key': demoKey,
          },
          body: jsonEncode({
            'state': state,
            'gateway_session_id': gatewaySessionId,
            if (routeMode != null) 'route_mode': routeMode,
            if (returnHops != null) 'return_hops': returnHops,
            if (retryCount != null) 'retry_count': retryCount,
            if (error != null) 'error': error,
            if (receiptId != null) 'receipt_id': receiptId,
            if (replyToEventId != null) 'reply_to_event_id': replyToEventId,
            if (senderEphemeralId != null)
              'sender_ephemeral_id': senderEphemeralId.toString(),
          }),
        )
        .timeout(requestTimeout);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> acknowledgeAuthorityCommand({
    required String gatewaySessionId,
    required String responseId,
    required int meshObjectId,
  }) async {
    final response = await _client
        .post(
          baseUrl.resolve(
            '/v1/gateways/${Uri.encodeComponent(gatewaySessionId)}/commands/${Uri.encodeComponent(responseId)}/received',
          ),
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-gateway-key': demoKey,
          },
          body: jsonEncode({'mesh_object_id': meshObjectId.toString()}),
        )
        .timeout(requestTimeout);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> uploadResponseReceipt({
    required String responseId,
    required String receiptId,
    required String replyToEventId,
    required int senderEphemeralId,
    required int createdAtMs,
  }) async {
    final response = await _client
        .post(
          baseUrl.resolve(
            '/v1/responses/${Uri.encodeComponent(responseId)}/receipts',
          ),
          headers: {
            'content-type': 'application/json',
            'x-meshsetu-gateway-key': demoKey,
          },
          body: jsonEncode({
            'receipt_id': receiptId,
            'reply_to_event_id': replyToEventId,
            'sender_ephemeral_id': senderEphemeralId.toString(),
            'created_at_ms': createdAtMs,
          }),
        )
        .timeout(requestTimeout);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Undelivered alerts addressed to this account (emergency-contact fan-out).
  Future<List<Map<String, Object?>>> fetchNotifications(
    String recipientUid,
  ) async {
    try {
      final response = await _client
          .get(baseUrl.resolve('/v1/notifications/$recipientUid'))
          .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) item.cast<String, Object?>(),
      ];
    } catch (_) {
      return const [];
    }
  }
}
