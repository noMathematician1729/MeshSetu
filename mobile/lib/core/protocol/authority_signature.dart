import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show EcPublicKey, KeyPairType;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

import 'return_protocol.dart';

/// The manifest representation is intentionally JWK-shaped so browser and
/// native clients can use the same public-key material without shipping PEM
/// parsing code. Only public x/y coordinates are accepted.
final class AuthorityPublicKeyJwk {
  const AuthorityPublicKeyJwk({
    required this.x,
    required this.y,
    this.kty = 'EC',
    this.crv = 'P-256',
  });

  final String kty;
  final String crv;
  final String x;
  final String y;

  factory AuthorityPublicKeyJwk.fromJson(Map<String, Object?> json) {
    final kty = json['kty'];
    final crv = json['crv'];
    final x = json['x'];
    final y = json['y'];
    if (kty != 'EC' || crv != 'P-256' || x is! String || y is! String) {
      throw const FormatException('unsupported authority public key JWK');
    }
    return AuthorityPublicKeyJwk(x: x, y: y);
  }

  Map<String, String> toJson() => {'kty': kty, 'crv': crv, 'x': x, 'y': y};

  EcPublicKey toEcPublicKey() {
    final xBytes = _decodeCoordinate(x);
    final yBytes = _decodeCoordinate(y);
    return EcPublicKey(x: xBytes, y: yBytes, type: KeyPairType.p256);
  }

  static Uint8List _decodeCoordinate(String value) {
    try {
      final decoded = base64Url.decode(base64Url.normalize(value));
      if (decoded.length != 32) {
        throw const FormatException('P-256 coordinate must be 32 bytes');
      }
      return Uint8List.fromList(decoded);
    } catch (error) {
      if (error is FormatException) rethrow;
      throw const FormatException('invalid base64url P-256 coordinate');
    }
  }
}

/// Verifies the exact serialized [ResponderUpdateBodyData] bytes. The wire
/// signature is IEEE P1363 `r || s`, exactly 64 bytes; DER signatures are
/// rejected before any cryptographic operation.
final class AuthoritySignatureVerifier {
  const AuthoritySignatureVerifier();

  Future<bool> verify({
    required EcPublicKey publicKey,
    required Uint8List body,
    required Uint8List signature,
  }) async {
    if (signature.length != ReturnProtocol.p1363SignatureBytes) return false;
    if (publicKey.type != KeyPairType.p256 ||
        publicKey.x.length != 32 ||
        publicKey.y.length != 32) {
      return false;
    }
    try {
      final domain = ECDomainParameters('secp256r1');
      final point = domain.curve.createPoint(
        _bytesToBigInt(publicKey.x),
        _bytesToBigInt(publicKey.y),
      );
      final signer = ECDSASigner(SHA256Digest());
      signer.init(
        false,
        PublicKeyParameter<PublicKey>(ECPublicKey(point, domain)),
      );
      final r = _bytesToBigInt(signature.sublist(0, 32));
      final s = _bytesToBigInt(signature.sublist(32, 64));
      return signer.verifySignature(
        Uint8List.fromList(body),
        ECSignature(r, s),
      );
    } catch (_) {
      return false;
    }
  }

  static BigInt _bytesToBigInt(List<int> bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }
    return value;
  }
}

final class AuthorityTrustSnapshot {
  const AuthorityTrustSnapshot({
    required this.siteId,
    required this.keyId,
    required this.publicKey,
  });

  final String siteId;
  final String keyId;
  final EcPublicKey publicKey;
}
