// This is a generated file - do not edit.
//
// Generated from meshsetu.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use priorityDescriptor instead')
const Priority$json = {
  '1': 'Priority',
  '2': [
    {'1': 'P_UNSPECIFIED', '2': 0},
    {'1': 'P0_CRITICAL', '2': 1},
    {'1': 'P1_HIGH', '2': 2},
    {'1': 'P2_NORMAL', '2': 3},
    {'1': 'P3_BULK', '2': 4},
  ],
};

/// Descriptor for `Priority`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List priorityDescriptor = $convert.base64Decode(
    'CghQcmlvcml0eRIRCg1QX1VOU1BFQ0lGSUVEEAASDwoLUDBfQ1JJVElDQUwQARILCgdQMV9ISU'
    'dIEAISDQoJUDJfTk9STUFMEAMSCwoHUDNfQlVMSxAE');

@$core.Deprecated('Use payloadTypeDescriptor instead')
const PayloadType$json = {
  '1': 'PayloadType',
  '2': [
    {'1': 'PT_UNSPECIFIED', '2': 0},
    {'1': 'STRUCTURED_SOS', '2': 1},
    {'1': 'ROOM_MESSAGE', '2': 2},
    {'1': 'VOICE_MANIFEST', '2': 3},
    {'1': 'VOICE_OBJECT', '2': 4},
    {'1': 'ACK', '2': 5},
    {'1': 'RESPONDER_UPDATE', '2': 6},
    {'1': 'BEACON_OBSERVATION', '2': 7},
    {'1': 'ROOM_VOICE', '2': 8},
  ],
};

/// Descriptor for `PayloadType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List payloadTypeDescriptor = $convert.base64Decode(
    'CgtQYXlsb2FkVHlwZRISCg5QVF9VTlNQRUNJRklFRBAAEhIKDlNUUlVDVFVSRURfU09TEAESEA'
    'oMUk9PTV9NRVNTQUdFEAISEgoOVk9JQ0VfTUFOSUZFU1QQAxIQCgxWT0lDRV9PQkpFQ1QQBBIH'
    'CgNBQ0sQBRIUChBSRVNQT05ERVJfVVBEQVRFEAYSFgoSQkVBQ09OX09CU0VSVkFUSU9OEAcSDg'
    'oKUk9PTV9WT0lDRRAI');

@$core.Deprecated('Use responseTypeDescriptor instead')
const ResponseType$json = {
  '1': 'ResponseType',
  '2': [
    {'1': 'RESPONSE_UNSPECIFIED', '2': 0},
    {'1': 'SOS_RECEIVED', '2': 1},
    {'1': 'HELP_DISPATCHED', '2': 2},
    {'1': 'SAFETY_GUIDANCE', '2': 3},
    {'1': 'INCIDENT_CLOSED', '2': 4},
  ],
};

/// Descriptor for `ResponseType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List responseTypeDescriptor = $convert.base64Decode(
    'CgxSZXNwb25zZVR5cGUSGAoUUkVTUE9OU0VfVU5TUEVDSUZJRUQQABIQCgxTT1NfUkVDRUlWRU'
    'QQARITCg9IRUxQX0RJU1BBVENIRUQQAhITCg9TQUZFVFlfR1VJREFOQ0UQAxITCg9JTkNJREVO'
    'VF9DTE9TRUQQBA==');

@$core.Deprecated('Use signatureAlgorithmDescriptor instead')
const SignatureAlgorithm$json = {
  '1': 'SignatureAlgorithm',
  '2': [
    {'1': 'SIG_UNSPECIFIED', '2': 0},
    {'1': 'ECDSA_P256_SHA256', '2': 1},
  ],
};

/// Descriptor for `SignatureAlgorithm`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List signatureAlgorithmDescriptor = $convert.base64Decode(
    'ChJTaWduYXR1cmVBbGdvcml0aG0SEwoPU0lHX1VOU1BFQ0lGSUVEEAASFQoRRUNEU0FfUDI1Nl'
    '9TSEEyNTYQAQ==');

@$core.Deprecated('Use ackKindDescriptor instead')
const AckKind$json = {
  '1': 'AckKind',
  '2': [
    {'1': 'ACK_KIND_UNSPECIFIED', '2': 0},
    {'1': 'OBJECT_RECEIVED', '2': 1},
    {'1': 'RESPONSE_DELIVERED', '2': 2},
  ],
};

/// Descriptor for `AckKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List ackKindDescriptor = $convert.base64Decode(
    'CgdBY2tLaW5kEhgKFEFDS19LSU5EX1VOU1BFQ0lGSUVEEAASEwoPT0JKRUNUX1JFQ0VJVkVEEA'
    'ESFgoSUkVTUE9OU0VfREVMSVZFUkVEEAI=');

@$core.Deprecated('Use meshEnvelopeDescriptor instead')
const MeshEnvelope$json = {
  '1': 'MeshEnvelope',
  '2': [
    {'1': 'object_id', '3': 1, '4': 1, '5': 4, '10': 'objectId'},
    {'1': 'event_id', '3': 2, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'site_id', '3': 3, '4': 1, '5': 9, '10': 'siteId'},
    {'1': 'room_id', '3': 4, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'created_at_ms', '3': 5, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'expires_at_ms', '3': 6, '4': 1, '5': 3, '10': 'expiresAtMs'},
    {'1': 'hop_count', '3': 7, '4': 1, '5': 13, '10': 'hopCount'},
    {'1': 'hop_limit', '3': 8, '4': 1, '5': 13, '10': 'hopLimit'},
    {
      '1': 'priority',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.meshsetu.v1.Priority',
      '10': 'priority'
    },
    {
      '1': 'payload_type',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.meshsetu.v1.PayloadType',
      '10': 'payloadType'
    },
    {'1': 'payload', '3': 11, '4': 1, '5': 12, '10': 'payload'},
    {
      '1': 'origin_ephemeral_id',
      '3': 12,
      '4': 1,
      '5': 4,
      '10': 'originEphemeralId'
    },
    {'1': 'trace_id', '3': 13, '4': 1, '5': 12, '10': 'traceId'},
  ],
};

/// Descriptor for `MeshEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List meshEnvelopeDescriptor = $convert.base64Decode(
    'CgxNZXNoRW52ZWxvcGUSGwoJb2JqZWN0X2lkGAEgASgEUghvYmplY3RJZBIZCghldmVudF9pZB'
    'gCIAEoCVIHZXZlbnRJZBIXCgdzaXRlX2lkGAMgASgJUgZzaXRlSWQSFwoHcm9vbV9pZBgEIAEo'
    'CVIGcm9vbUlkEiIKDWNyZWF0ZWRfYXRfbXMYBSABKANSC2NyZWF0ZWRBdE1zEiIKDWV4cGlyZX'
    'NfYXRfbXMYBiABKANSC2V4cGlyZXNBdE1zEhsKCWhvcF9jb3VudBgHIAEoDVIIaG9wQ291bnQS'
    'GwoJaG9wX2xpbWl0GAggASgNUghob3BMaW1pdBIxCghwcmlvcml0eRgJIAEoDjIVLm1lc2hzZX'
    'R1LnYxLlByaW9yaXR5Ughwcmlvcml0eRI7CgxwYXlsb2FkX3R5cGUYCiABKA4yGC5tZXNoc2V0'
    'dS52MS5QYXlsb2FkVHlwZVILcGF5bG9hZFR5cGUSGAoHcGF5bG9hZBgLIAEoDFIHcGF5bG9hZB'
    'IuChNvcmlnaW5fZXBoZW1lcmFsX2lkGAwgASgEUhFvcmlnaW5FcGhlbWVyYWxJZBIZCgh0cmFj'
    'ZV9pZBgNIAEoDFIHdHJhY2VJZA==');

@$core.Deprecated('Use responderUpdateBodyDescriptor instead')
const ResponderUpdateBody$json = {
  '1': 'ResponderUpdateBody',
  '2': [
    {'1': 'response_id', '3': 1, '4': 1, '5': 9, '10': 'responseId'},
    {'1': 'reply_to_event_id', '3': 2, '4': 1, '5': 9, '10': 'replyToEventId'},
    {
      '1': 'destination_ephemeral_id',
      '3': 3,
      '4': 1,
      '5': 6,
      '10': 'destinationEphemeralId'
    },
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.meshsetu.v1.ResponseType',
      '10': 'type'
    },
    {'1': 'message_text', '3': 5, '4': 1, '5': 9, '10': 'messageText'},
    {'1': 'created_at_ms', '3': 6, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'expires_at_ms', '3': 7, '4': 1, '5': 3, '10': 'expiresAtMs'},
    {'1': 'site_id', '3': 8, '4': 1, '5': 9, '10': 'siteId'},
    {
      '1': 'original_trace_id',
      '3': 9,
      '4': 1,
      '5': 12,
      '10': 'originalTraceId'
    },
  ],
};

/// Descriptor for `ResponderUpdateBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responderUpdateBodyDescriptor = $convert.base64Decode(
    'ChNSZXNwb25kZXJVcGRhdGVCb2R5Eh8KC3Jlc3BvbnNlX2lkGAEgASgJUgpyZXNwb25zZUlkEi'
    'kKEXJlcGx5X3RvX2V2ZW50X2lkGAIgASgJUg5yZXBseVRvRXZlbnRJZBI4ChhkZXN0aW5hdGlv'
    'bl9lcGhlbWVyYWxfaWQYAyABKAZSFmRlc3RpbmF0aW9uRXBoZW1lcmFsSWQSLQoEdHlwZRgEIA'
    'EoDjIZLm1lc2hzZXR1LnYxLlJlc3BvbnNlVHlwZVIEdHlwZRIhCgxtZXNzYWdlX3RleHQYBSAB'
    'KAlSC21lc3NhZ2VUZXh0EiIKDWNyZWF0ZWRfYXRfbXMYBiABKANSC2NyZWF0ZWRBdE1zEiIKDW'
    'V4cGlyZXNfYXRfbXMYByABKANSC2V4cGlyZXNBdE1zEhcKB3NpdGVfaWQYCCABKAlSBnNpdGVJ'
    'ZBIqChFvcmlnaW5hbF90cmFjZV9pZBgJIAEoDFIPb3JpZ2luYWxUcmFjZUlk');

@$core.Deprecated('Use signedResponderUpdateDescriptor instead')
const SignedResponderUpdate$json = {
  '1': 'SignedResponderUpdate',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 12, '10': 'body'},
    {
      '1': 'authority_signature',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'authoritySignature'
    },
    {'1': 'authority_key_id', '3': 3, '4': 1, '5': 9, '10': 'authorityKeyId'},
    {
      '1': 'algorithm',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.meshsetu.v1.SignatureAlgorithm',
      '10': 'algorithm'
    },
  ],
};

/// Descriptor for `SignedResponderUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signedResponderUpdateDescriptor = $convert.base64Decode(
    'ChVTaWduZWRSZXNwb25kZXJVcGRhdGUSEgoEYm9keRgBIAEoDFIEYm9keRIvChNhdXRob3JpdH'
    'lfc2lnbmF0dXJlGAIgASgMUhJhdXRob3JpdHlTaWduYXR1cmUSKAoQYXV0aG9yaXR5X2tleV9p'
    'ZBgDIAEoCVIOYXV0aG9yaXR5S2V5SWQSPQoJYWxnb3JpdGhtGAQgASgOMh8ubWVzaHNldHUudj'
    'EuU2lnbmF0dXJlQWxnb3JpdGhtUglhbGdvcml0aG0=');

@$core.Deprecated('Use ackMessageDescriptor instead')
const AckMessage$json = {
  '1': 'AckMessage',
  '2': [
    {'1': 'ack_id', '3': 1, '4': 1, '5': 9, '10': 'ackId'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.meshsetu.v1.AckKind',
      '10': 'kind'
    },
    {'1': 'acked_object_id', '3': 3, '4': 1, '5': 6, '10': 'ackedObjectId'},
    {'1': 'response_id', '3': 4, '4': 1, '5': 9, '10': 'responseId'},
    {'1': 'reply_to_event_id', '3': 5, '4': 1, '5': 9, '10': 'replyToEventId'},
    {
      '1': 'sender_ephemeral_id',
      '3': 6,
      '4': 1,
      '5': 6,
      '10': 'senderEphemeralId'
    },
    {'1': 'created_at_ms', '3': 7, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'expires_at_ms', '3': 8, '4': 1, '5': 3, '10': 'expiresAtMs'},
  ],
};

/// Descriptor for `AckMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ackMessageDescriptor = $convert.base64Decode(
    'CgpBY2tNZXNzYWdlEhUKBmFja19pZBgBIAEoCVIFYWNrSWQSKAoEa2luZBgCIAEoDjIULm1lc2'
    'hzZXR1LnYxLkFja0tpbmRSBGtpbmQSJgoPYWNrZWRfb2JqZWN0X2lkGAMgASgGUg1hY2tlZE9i'
    'amVjdElkEh8KC3Jlc3BvbnNlX2lkGAQgASgJUgpyZXNwb25zZUlkEikKEXJlcGx5X3RvX2V2ZW'
    '50X2lkGAUgASgJUg5yZXBseVRvRXZlbnRJZBIuChNzZW5kZXJfZXBoZW1lcmFsX2lkGAYgASgG'
    'UhFzZW5kZXJFcGhlbWVyYWxJZBIiCg1jcmVhdGVkX2F0X21zGAcgASgDUgtjcmVhdGVkQXRNcx'
    'IiCg1leHBpcmVzX2F0X21zGAggASgDUgtleHBpcmVzQXRNcw==');
