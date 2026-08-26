// This is a generated file - do not edit.
//
// Generated from meshsetu.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Priority extends $pb.ProtobufEnum {
  static const Priority P_UNSPECIFIED =
      Priority._(0, _omitEnumNames ? '' : 'P_UNSPECIFIED');
  static const Priority P0_CRITICAL =
      Priority._(1, _omitEnumNames ? '' : 'P0_CRITICAL');
  static const Priority P1_HIGH =
      Priority._(2, _omitEnumNames ? '' : 'P1_HIGH');
  static const Priority P2_NORMAL =
      Priority._(3, _omitEnumNames ? '' : 'P2_NORMAL');
  static const Priority P3_BULK =
      Priority._(4, _omitEnumNames ? '' : 'P3_BULK');

  static const $core.List<Priority> values = <Priority>[
    P_UNSPECIFIED,
    P0_CRITICAL,
    P1_HIGH,
    P2_NORMAL,
    P3_BULK,
  ];

  static final $core.List<Priority?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Priority? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Priority._(super.value, super.name);
}

class PayloadType extends $pb.ProtobufEnum {
  static const PayloadType PT_UNSPECIFIED =
      PayloadType._(0, _omitEnumNames ? '' : 'PT_UNSPECIFIED');
  static const PayloadType STRUCTURED_SOS =
      PayloadType._(1, _omitEnumNames ? '' : 'STRUCTURED_SOS');
  static const PayloadType ROOM_MESSAGE =
      PayloadType._(2, _omitEnumNames ? '' : 'ROOM_MESSAGE');
  static const PayloadType VOICE_MANIFEST =
      PayloadType._(3, _omitEnumNames ? '' : 'VOICE_MANIFEST');
  static const PayloadType VOICE_OBJECT =
      PayloadType._(4, _omitEnumNames ? '' : 'VOICE_OBJECT');
  static const PayloadType ACK = PayloadType._(5, _omitEnumNames ? '' : 'ACK');
  static const PayloadType RESPONDER_UPDATE =
      PayloadType._(6, _omitEnumNames ? '' : 'RESPONDER_UPDATE');
  static const PayloadType BEACON_OBSERVATION =
      PayloadType._(7, _omitEnumNames ? '' : 'BEACON_OBSERVATION');

  /// Push-to-talk voice note authored inside a Room. Distinct from
  /// VOICE_OBJECT, which is SOS evidence and is forwarded to the control
  /// room; room voice stays inside the room's membership.
  static const PayloadType ROOM_VOICE =
      PayloadType._(8, _omitEnumNames ? '' : 'ROOM_VOICE');

  static const $core.List<PayloadType> values = <PayloadType>[
    PT_UNSPECIFIED,
    STRUCTURED_SOS,
    ROOM_MESSAGE,
    VOICE_MANIFEST,
    VOICE_OBJECT,
    ACK,
    RESPONDER_UPDATE,
    BEACON_OBSERVATION,
    ROOM_VOICE,
  ];

  static final $core.List<PayloadType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static PayloadType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PayloadType._(super.value, super.name);
}

class ResponseType extends $pb.ProtobufEnum {
  static const ResponseType RESPONSE_UNSPECIFIED =
      ResponseType._(0, _omitEnumNames ? '' : 'RESPONSE_UNSPECIFIED');
  static const ResponseType SOS_RECEIVED =
      ResponseType._(1, _omitEnumNames ? '' : 'SOS_RECEIVED');
  static const ResponseType HELP_DISPATCHED =
      ResponseType._(2, _omitEnumNames ? '' : 'HELP_DISPATCHED');
  static const ResponseType SAFETY_GUIDANCE =
      ResponseType._(3, _omitEnumNames ? '' : 'SAFETY_GUIDANCE');
  static const ResponseType INCIDENT_CLOSED =
      ResponseType._(4, _omitEnumNames ? '' : 'INCIDENT_CLOSED');

  static const $core.List<ResponseType> values = <ResponseType>[
    RESPONSE_UNSPECIFIED,
    SOS_RECEIVED,
    HELP_DISPATCHED,
    SAFETY_GUIDANCE,
    INCIDENT_CLOSED,
  ];

  static final $core.List<ResponseType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ResponseType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ResponseType._(super.value, super.name);
}

class SignatureAlgorithm extends $pb.ProtobufEnum {
  static const SignatureAlgorithm SIG_UNSPECIFIED =
      SignatureAlgorithm._(0, _omitEnumNames ? '' : 'SIG_UNSPECIFIED');
  static const SignatureAlgorithm ECDSA_P256_SHA256 =
      SignatureAlgorithm._(1, _omitEnumNames ? '' : 'ECDSA_P256_SHA256');

  static const $core.List<SignatureAlgorithm> values = <SignatureAlgorithm>[
    SIG_UNSPECIFIED,
    ECDSA_P256_SHA256,
  ];

  static final $core.List<SignatureAlgorithm?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static SignatureAlgorithm? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SignatureAlgorithm._(super.value, super.name);
}

class AckKind extends $pb.ProtobufEnum {
  static const AckKind ACK_KIND_UNSPECIFIED =
      AckKind._(0, _omitEnumNames ? '' : 'ACK_KIND_UNSPECIFIED');
  static const AckKind OBJECT_RECEIVED =
      AckKind._(1, _omitEnumNames ? '' : 'OBJECT_RECEIVED');
  static const AckKind RESPONSE_DELIVERED =
      AckKind._(2, _omitEnumNames ? '' : 'RESPONSE_DELIVERED');

  static const $core.List<AckKind> values = <AckKind>[
    ACK_KIND_UNSPECIFIED,
    OBJECT_RECEIVED,
    RESPONSE_DELIVERED,
  ];

  static final $core.List<AckKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AckKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AckKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
