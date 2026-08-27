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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'meshsetu.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'meshsetu.pbenum.dart';

class MeshEnvelope extends $pb.GeneratedMessage {
  factory MeshEnvelope({
    $fixnum.Int64? objectId,
    $core.String? eventId,
    $core.String? siteId,
    $core.String? roomId,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? expiresAtMs,
    $core.int? hopCount,
    $core.int? hopLimit,
    Priority? priority,
    PayloadType? payloadType,
    $core.List<$core.int>? payload,
    $fixnum.Int64? originEphemeralId,
    $core.List<$core.int>? traceId,
  }) {
    final result = create();
    if (objectId != null) result.objectId = objectId;
    if (eventId != null) result.eventId = eventId;
    if (siteId != null) result.siteId = siteId;
    if (roomId != null) result.roomId = roomId;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    if (hopCount != null) result.hopCount = hopCount;
    if (hopLimit != null) result.hopLimit = hopLimit;
    if (priority != null) result.priority = priority;
    if (payloadType != null) result.payloadType = payloadType;
    if (payload != null) result.payload = payload;
    if (originEphemeralId != null) result.originEphemeralId = originEphemeralId;
    if (traceId != null) result.traceId = traceId;
    return result;
  }

  MeshEnvelope._();

  factory MeshEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MeshEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MeshEnvelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshsetu.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'objectId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'eventId')
    ..aOS(3, _omitFieldNames ? '' : 'siteId')
    ..aOS(4, _omitFieldNames ? '' : 'roomId')
    ..aInt64(5, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(6, _omitFieldNames ? '' : 'expiresAtMs')
    ..aI(7, _omitFieldNames ? '' : 'hopCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'hopLimit', fieldType: $pb.PbFieldType.OU3)
    ..aE<Priority>(9, _omitFieldNames ? '' : 'priority',
        enumValues: Priority.values)
    ..aE<PayloadType>(10, _omitFieldNames ? '' : 'payloadType',
        enumValues: PayloadType.values)
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        12, _omitFieldNames ? '' : 'originEphemeralId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        13, _omitFieldNames ? '' : 'traceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeshEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeshEnvelope copyWith(void Function(MeshEnvelope) updates) =>
      super.copyWith((message) => updates(message as MeshEnvelope))
          as MeshEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MeshEnvelope create() => MeshEnvelope._();
  @$core.override
  MeshEnvelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MeshEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MeshEnvelope>(create);
  static MeshEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get objectId => $_getI64(0);
  @$pb.TagNumber(1)
  set objectId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjectId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get eventId => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get siteId => $_getSZ(2);
  @$pb.TagNumber(3)
  set siteId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSiteId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSiteId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get roomId => $_getSZ(3);
  @$pb.TagNumber(4)
  set roomId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRoomId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoomId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get expiresAtMs => $_getI64(5);
  @$pb.TagNumber(6)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExpiresAtMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpiresAtMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get hopCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set hopCount($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHopCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearHopCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get hopLimit => $_getIZ(7);
  @$pb.TagNumber(8)
  set hopLimit($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHopLimit() => $_has(7);
  @$pb.TagNumber(8)
  void clearHopLimit() => $_clearField(8);

  @$pb.TagNumber(9)
  Priority get priority => $_getN(8);
  @$pb.TagNumber(9)
  set priority(Priority value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPriority() => $_has(8);
  @$pb.TagNumber(9)
  void clearPriority() => $_clearField(9);

  @$pb.TagNumber(10)
  PayloadType get payloadType => $_getN(9);
  @$pb.TagNumber(10)
  set payloadType(PayloadType value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPayloadType() => $_has(9);
  @$pb.TagNumber(10)
  void clearPayloadType() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get payload => $_getN(10);
  @$pb.TagNumber(11)
  set payload($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPayload() => $_has(10);
  @$pb.TagNumber(11)
  void clearPayload() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get originEphemeralId => $_getI64(11);
  @$pb.TagNumber(12)
  set originEphemeralId($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasOriginEphemeralId() => $_has(11);
  @$pb.TagNumber(12)
  void clearOriginEphemeralId() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.List<$core.int> get traceId => $_getN(12);
  @$pb.TagNumber(13)
  set traceId($core.List<$core.int> value) => $_setBytes(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTraceId() => $_has(12);
  @$pb.TagNumber(13)
  void clearTraceId() => $_clearField(13);
}

class ResponderUpdateBody extends $pb.GeneratedMessage {
  factory ResponderUpdateBody({
    $core.String? responseId,
    $core.String? replyToEventId,
    $fixnum.Int64? destinationEphemeralId,
    ResponseType? type,
    $core.String? messageText,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? expiresAtMs,
    $core.String? siteId,
    $core.List<$core.int>? originalTraceId,
  }) {
    final result = create();
    if (responseId != null) result.responseId = responseId;
    if (replyToEventId != null) result.replyToEventId = replyToEventId;
    if (destinationEphemeralId != null)
      result.destinationEphemeralId = destinationEphemeralId;
    if (type != null) result.type = type;
    if (messageText != null) result.messageText = messageText;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    if (siteId != null) result.siteId = siteId;
    if (originalTraceId != null) result.originalTraceId = originalTraceId;
    return result;
  }

  ResponderUpdateBody._();

  factory ResponderUpdateBody.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponderUpdateBody.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponderUpdateBody',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshsetu.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'responseId')
    ..aOS(2, _omitFieldNames ? '' : 'replyToEventId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'destinationEphemeralId', $pb.PbFieldType.OF6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<ResponseType>(4, _omitFieldNames ? '' : 'type',
        enumValues: ResponseType.values)
    ..aOS(5, _omitFieldNames ? '' : 'messageText')
    ..aInt64(6, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(7, _omitFieldNames ? '' : 'expiresAtMs')
    ..aOS(8, _omitFieldNames ? '' : 'siteId')
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'originalTraceId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponderUpdateBody clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponderUpdateBody copyWith(void Function(ResponderUpdateBody) updates) =>
      super.copyWith((message) => updates(message as ResponderUpdateBody))
          as ResponderUpdateBody;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponderUpdateBody create() => ResponderUpdateBody._();
  @$core.override
  ResponderUpdateBody createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponderUpdateBody getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponderUpdateBody>(create);
  static ResponderUpdateBody? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get responseId => $_getSZ(0);
  @$pb.TagNumber(1)
  set responseId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResponseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResponseId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get replyToEventId => $_getSZ(1);
  @$pb.TagNumber(2)
  set replyToEventId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReplyToEventId() => $_has(1);
  @$pb.TagNumber(2)
  void clearReplyToEventId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get destinationEphemeralId => $_getI64(2);
  @$pb.TagNumber(3)
  set destinationEphemeralId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDestinationEphemeralId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDestinationEphemeralId() => $_clearField(3);

  @$pb.TagNumber(4)
  ResponseType get type => $_getN(3);
  @$pb.TagNumber(4)
  set type(ResponseType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get messageText => $_getSZ(4);
  @$pb.TagNumber(5)
  set messageText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessageText() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessageText() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createdAtMs => $_getI64(5);
  @$pb.TagNumber(6)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAtMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAtMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get expiresAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExpiresAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpiresAtMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get siteId => $_getSZ(7);
  @$pb.TagNumber(8)
  set siteId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSiteId() => $_has(7);
  @$pb.TagNumber(8)
  void clearSiteId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get originalTraceId => $_getN(8);
  @$pb.TagNumber(9)
  set originalTraceId($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOriginalTraceId() => $_has(8);
  @$pb.TagNumber(9)
  void clearOriginalTraceId() => $_clearField(9);
}

class SignedResponderUpdate extends $pb.GeneratedMessage {
  factory SignedResponderUpdate({
    $core.List<$core.int>? body,
    $core.List<$core.int>? authoritySignature,
    $core.String? authorityKeyId,
    SignatureAlgorithm? algorithm,
  }) {
    final result = create();
    if (body != null) result.body = body;
    if (authoritySignature != null)
      result.authoritySignature = authoritySignature;
    if (authorityKeyId != null) result.authorityKeyId = authorityKeyId;
    if (algorithm != null) result.algorithm = algorithm;
    return result;
  }

  SignedResponderUpdate._();

  factory SignedResponderUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignedResponderUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignedResponderUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshsetu.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'authoritySignature', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'authorityKeyId')
    ..aE<SignatureAlgorithm>(4, _omitFieldNames ? '' : 'algorithm',
        enumValues: SignatureAlgorithm.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignedResponderUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignedResponderUpdate copyWith(
          void Function(SignedResponderUpdate) updates) =>
      super.copyWith((message) => updates(message as SignedResponderUpdate))
          as SignedResponderUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignedResponderUpdate create() => SignedResponderUpdate._();
  @$core.override
  SignedResponderUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SignedResponderUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignedResponderUpdate>(create);
  static SignedResponderUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get body => $_getN(0);
  @$pb.TagNumber(1)
  set body($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get authoritySignature => $_getN(1);
  @$pb.TagNumber(2)
  set authoritySignature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthoritySignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthoritySignature() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get authorityKeyId => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorityKeyId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorityKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorityKeyId() => $_clearField(3);

  @$pb.TagNumber(4)
  SignatureAlgorithm get algorithm => $_getN(3);
  @$pb.TagNumber(4)
  set algorithm(SignatureAlgorithm value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAlgorithm() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlgorithm() => $_clearField(4);
}

class AckMessage extends $pb.GeneratedMessage {
  factory AckMessage({
    $core.String? ackId,
    AckKind? kind,
    $fixnum.Int64? ackedObjectId,
    $core.String? responseId,
    $core.String? replyToEventId,
    $fixnum.Int64? senderEphemeralId,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? expiresAtMs,
  }) {
    final result = create();
    if (ackId != null) result.ackId = ackId;
    if (kind != null) result.kind = kind;
    if (ackedObjectId != null) result.ackedObjectId = ackedObjectId;
    if (responseId != null) result.responseId = responseId;
    if (replyToEventId != null) result.replyToEventId = replyToEventId;
    if (senderEphemeralId != null) result.senderEphemeralId = senderEphemeralId;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (expiresAtMs != null) result.expiresAtMs = expiresAtMs;
    return result;
  }

  AckMessage._();

  factory AckMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AckMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AckMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'meshsetu.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ackId')
    ..aE<AckKind>(2, _omitFieldNames ? '' : 'kind', enumValues: AckKind.values)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'ackedObjectId', $pb.PbFieldType.OF6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'responseId')
    ..aOS(5, _omitFieldNames ? '' : 'replyToEventId')
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'senderEphemeralId', $pb.PbFieldType.OF6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(7, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(8, _omitFieldNames ? '' : 'expiresAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckMessage copyWith(void Function(AckMessage) updates) =>
      super.copyWith((message) => updates(message as AckMessage)) as AckMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AckMessage create() => AckMessage._();
  @$core.override
  AckMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AckMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AckMessage>(create);
  static AckMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ackId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ackId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAckId() => $_clearField(1);

  @$pb.TagNumber(2)
  AckKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(AckKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get ackedObjectId => $_getI64(2);
  @$pb.TagNumber(3)
  set ackedObjectId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAckedObjectId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAckedObjectId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get responseId => $_getSZ(3);
  @$pb.TagNumber(4)
  set responseId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasResponseId() => $_has(3);
  @$pb.TagNumber(4)
  void clearResponseId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get replyToEventId => $_getSZ(4);
  @$pb.TagNumber(5)
  set replyToEventId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReplyToEventId() => $_has(4);
  @$pb.TagNumber(5)
  void clearReplyToEventId() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get senderEphemeralId => $_getI64(5);
  @$pb.TagNumber(6)
  set senderEphemeralId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSenderEphemeralId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSenderEphemeralId() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get createdAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAtMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get expiresAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set expiresAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasExpiresAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearExpiresAtMs() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
