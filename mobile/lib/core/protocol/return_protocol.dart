import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../generated/meshsetu.pb.dart' as pb;

/// Authority response types are deliberately explicit. UI copy and server
/// authorization must switch on this value rather than infer intent from text.
enum ReturnResponseType {
  sosReceived,
  helpDispatched,
  safetyGuidance,
  incidentClosed,
}

enum ReturnSignatureAlgorithm { ecdsaP256Sha256 }

enum AckKind { objectReceived, responseDelivered }

final class ResponderUpdateBodyData {
  const ResponderUpdateBodyData({
    required this.responseId,
    required this.replyToEventId,
    required this.destinationEphemeralId,
    required this.type,
    required this.messageText,
    required this.createdAtMs,
    required this.expiresAtMs,
    required this.siteId,
    required this.originalTraceId,
  });

  final String responseId;
  final String replyToEventId;
  final int destinationEphemeralId;
  final ReturnResponseType type;
  final String messageText;
  final int createdAtMs;
  final int expiresAtMs;
  final String siteId;
  final Uint8List originalTraceId;

  Uint8List toBytes() => ReturnProtocol.encodeBody(this);
}

final class SignedResponderUpdateData {
  const SignedResponderUpdateData({
    required this.body,
    required this.bodyBytes,
    required this.authoritySignature,
    required this.authorityKeyId,
    required this.algorithm,
  });

  final ResponderUpdateBodyData body;
  final Uint8List bodyBytes;
  final Uint8List authoritySignature;
  final String authorityKeyId;
  final ReturnSignatureAlgorithm algorithm;
}

final class AckMessageData {
  const AckMessageData({
    required this.ackId,
    required this.kind,
    required this.ackedObjectId,
    required this.responseId,
    required this.replyToEventId,
    required this.senderEphemeralId,
    required this.createdAtMs,
    required this.expiresAtMs,
  });

  final String ackId;
  final AckKind kind;
  final int ackedObjectId;
  final String responseId;
  final String replyToEventId;
  final int senderEphemeralId;
  final int createdAtMs;
  final int expiresAtMs;
}

abstract final class ReturnProtocol {
  static const int maxMessageUtf8Bytes = 256;
  static const int p1363SignatureBytes = 64;

  static Uint8List encodeBody(ResponderUpdateBodyData value) {
    final message = pb.ResponderUpdateBody(
      responseId: value.responseId,
      replyToEventId: value.replyToEventId,
      destinationEphemeralId: Int64(value.destinationEphemeralId),
      type: _responseTypeToProto(value.type),
      messageText: value.messageText,
      createdAtMs: Int64(value.createdAtMs),
      expiresAtMs: Int64(value.expiresAtMs),
      siteId: value.siteId,
      originalTraceId: value.originalTraceId,
    );
    final textBytes = utf8.encode(value.messageText);
    if (textBytes.length > maxMessageUtf8Bytes) {
      throw ArgumentError('messageText exceeds 256 UTF-8 bytes');
    }
    if (value.responseId.trim().isEmpty ||
        value.replyToEventId.trim().isEmpty ||
        value.siteId.trim().isEmpty) {
      throw ArgumentError('response, event, and site IDs must not be blank');
    }
    if (value.expiresAtMs <= value.createdAtMs) {
      throw ArgumentError('response expiry must be after creation');
    }
    return Uint8List.fromList(message.writeToBuffer());
  }

  static ResponderUpdateBodyData decodeBody(Uint8List bytes) {
    final value = pb.ResponderUpdateBody.fromBuffer(bytes);
    final messageBytes = utf8.encode(value.messageText);
    if (messageBytes.length > maxMessageUtf8Bytes) {
      throw FormatException('messageText exceeds 256 UTF-8 bytes');
    }
    return ResponderUpdateBodyData(
      responseId: value.responseId,
      replyToEventId: value.replyToEventId,
      destinationEphemeralId: value.destinationEphemeralId.toInt(),
      type: _responseTypeFromProto(value.type),
      messageText: value.messageText,
      createdAtMs: value.createdAtMs.toInt(),
      expiresAtMs: value.expiresAtMs.toInt(),
      siteId: value.siteId,
      originalTraceId: Uint8List.fromList(value.originalTraceId),
    );
  }

  static Uint8List encodeSigned(SignedResponderUpdateData value) {
    if (value.authoritySignature.length != p1363SignatureBytes) {
      throw ArgumentError('authority signature must be 64-byte IEEE P1363');
    }
    final message = pb.SignedResponderUpdate(
      body: value.body.toBytes(),
      authoritySignature: value.authoritySignature,
      authorityKeyId: value.authorityKeyId,
      algorithm: _algorithmToProto(value.algorithm),
    );
    return Uint8List.fromList(message.writeToBuffer());
  }

  static SignedResponderUpdateData decodeSigned(Uint8List bytes) {
    final value = pb.SignedResponderUpdate.fromBuffer(bytes);
    if (value.authoritySignature.length != p1363SignatureBytes) {
      throw FormatException('authority signature must be 64-byte IEEE P1363');
    }
    return SignedResponderUpdateData(
      body: decodeBody(Uint8List.fromList(value.body)),
      bodyBytes: Uint8List.fromList(value.body),
      authoritySignature: Uint8List.fromList(value.authoritySignature),
      authorityKeyId: value.authorityKeyId,
      algorithm: _algorithmFromProto(value.algorithm),
    );
  }

  static Uint8List encodeAck(AckMessageData value) {
    final message = pb.AckMessage(
      ackId: value.ackId,
      kind: _ackKindToProto(value.kind),
      ackedObjectId: Int64(value.ackedObjectId),
      responseId: value.responseId,
      replyToEventId: value.replyToEventId,
      senderEphemeralId: Int64(value.senderEphemeralId),
      createdAtMs: Int64(value.createdAtMs),
      expiresAtMs: Int64(value.expiresAtMs),
    );
    return Uint8List.fromList(message.writeToBuffer());
  }

  static AckMessageData decodeAck(Uint8List bytes) {
    final value = pb.AckMessage.fromBuffer(bytes);
    return AckMessageData(
      ackId: value.ackId,
      kind: _ackKindFromProto(value.kind),
      ackedObjectId: value.ackedObjectId.toInt(),
      responseId: value.responseId,
      replyToEventId: value.replyToEventId,
      senderEphemeralId: value.senderEphemeralId.toInt(),
      createdAtMs: value.createdAtMs.toInt(),
      expiresAtMs: value.expiresAtMs.toInt(),
    );
  }

  static pb.ResponseType _responseTypeToProto(ReturnResponseType value) =>
      switch (value) {
        ReturnResponseType.sosReceived => pb.ResponseType.SOS_RECEIVED,
        ReturnResponseType.helpDispatched => pb.ResponseType.HELP_DISPATCHED,
        ReturnResponseType.safetyGuidance => pb.ResponseType.SAFETY_GUIDANCE,
        ReturnResponseType.incidentClosed => pb.ResponseType.INCIDENT_CLOSED,
      };

  static ReturnResponseType _responseTypeFromProto(pb.ResponseType value) =>
      switch (value) {
        pb.ResponseType.SOS_RECEIVED => ReturnResponseType.sosReceived,
        pb.ResponseType.HELP_DISPATCHED => ReturnResponseType.helpDispatched,
        pb.ResponseType.SAFETY_GUIDANCE => ReturnResponseType.safetyGuidance,
        pb.ResponseType.INCIDENT_CLOSED => ReturnResponseType.incidentClosed,
        _ => throw FormatException('unsupported response type'),
      };

  static pb.SignatureAlgorithm _algorithmToProto(
    ReturnSignatureAlgorithm value,
  ) => switch (value) {
    ReturnSignatureAlgorithm.ecdsaP256Sha256 =>
      pb.SignatureAlgorithm.ECDSA_P256_SHA256,
  };

  static ReturnSignatureAlgorithm _algorithmFromProto(
    pb.SignatureAlgorithm value,
  ) => switch (value) {
    pb.SignatureAlgorithm.ECDSA_P256_SHA256 =>
      ReturnSignatureAlgorithm.ecdsaP256Sha256,
    _ => throw FormatException('unsupported signature algorithm'),
  };

  static pb.AckKind _ackKindToProto(AckKind value) => switch (value) {
    AckKind.objectReceived => pb.AckKind.OBJECT_RECEIVED,
    AckKind.responseDelivered => pb.AckKind.RESPONSE_DELIVERED,
  };

  static AckKind _ackKindFromProto(pb.AckKind value) => switch (value) {
    pb.AckKind.OBJECT_RECEIVED => AckKind.objectReceived,
    pb.AckKind.RESPONSE_DELIVERED => AckKind.responseDelivered,
    _ => throw FormatException('unsupported ack kind'),
  };
}
