import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meshsetu_mobile/core/protocol/authority_signature.dart';
import 'package:meshsetu_mobile/core/protocol/return_protocol.dart';
import 'package:meshsetu_mobile/core/security/authority_key_store.dart';
import 'package:meshsetu_mobile/feature/join/manifest.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Object?> vector;
  late Uint8List body;
  late Uint8List signature;
  late AuthorityPublicKeyJwk jwk;

  setUpAll(() {
    vector = jsonDecode(
          File('test/fixtures/authority_vectors.json').readAsStringSync(),
        )
        as Map<String, Object?>;
    body = base64Decode(vector['bodyB64']! as String);
    signature = base64Decode(vector['signatureB64']! as String);
    jwk = AuthorityPublicKeyJwk.fromJson(
      Map<String, Object?>.from(vector['publicKeyJwk']! as Map),
    );
  });

  test('decodes the Node-produced signed update and preserves fixed64 ID', () {
    final signed = ReturnProtocol.decodeSigned(
      Uint8List.fromList(base64Decode(vector['signedB64']! as String)),
    );
    expect(signed.body.responseId, 'response-vector-1');
    expect(signed.body.replyToEventId, 'event-vector-1');
    expect(signed.body.destinationEphemeralId, 123456789);
    expect(signed.body.siteId, 'vector-site');
    expect(signed.authoritySignature, orderedEquals(signature));
  });

  test('verifies Node ECDSA P-256 IEEE P1363 signature', () async {
    final verifier = const AuthoritySignatureVerifier();
    expect(
      await verifier.verify(
        publicKey: jwk.toEcPublicKey(),
        body: body,
        signature: signature,
      ),
      isTrue,
    );
  });

  test('rejects body, signature, DER-length, and wrong-key tampering', () async {
    final verifier = const AuthoritySignatureVerifier();
    final bodyTampered = Uint8List.fromList(body)..[body.length - 1] ^= 1;
    final signatureTampered = Uint8List.fromList(signature)
      ..[signature.length - 1] ^= 1;
    expect(
      await verifier.verify(
        publicKey: jwk.toEcPublicKey(),
        body: bodyTampered,
        signature: signature,
      ),
      isFalse,
    );
    expect(
      await verifier.verify(
        publicKey: jwk.toEcPublicKey(),
        body: body,
        signature: signatureTampered,
      ),
      isFalse,
    );
    expect(
      await verifier.verify(
        publicKey: jwk.toEcPublicKey(),
        body: body,
        signature: Uint8List(70),
      ),
      isFalse,
    );
    final wrongKey = AuthorityPublicKeyJwk(
      x: jwk.x,
      y: base64Url.encode(Uint8List(32)),
    );
    expect(
      await verifier.verify(
        publicKey: wrongKey.toEcPublicKey(),
        body: body,
        signature: signature,
      ),
      isFalse,
    );
  });

  test('manifest HMAC covers authority key fields and key store pins key ID', () {
    final manifest = EventManifest(
      siteId: 'vector-site',
      siteName: 'Vector Site',
      meshCode: 'VECTOR',
      validFromMs: 0,
      validUntilMs: 9999999999999,
      gatewayHint: '',
      authorityKeyId: vector['keyId']! as String,
      authorityPublicKeyJwk: Map<String, String>.from(
        (vector['publicKeyJwk']! as Map).map(
          (key, value) => MapEntry(key as String, value as String),
        ),
      ),
      rooms: const [],
    );
    final encoded = EventManifestCodec.encode(manifest);
    final decoded = EventManifestCodec.decode(encoded)!;
    expect(decoded.signatureValid, isTrue);
    expect(decoded.manifest.authorityKeyId, manifest.authorityKeyId);
    expect(
      AuthorityKeyStore().resolve(
        manifest: decoded.manifest,
        keyId: manifest.authorityKeyId,
      ),
      isA<EcPublicKey>(),
    );
    expect(
      AuthorityKeyStore().resolve(
        manifest: decoded.manifest,
        keyId: 'attacker-key',
      ),
      isNull,
    );
    final tampered = encoded.replaceFirst(
      jwk.x,
      base64Url.encode(Uint8List(32)),
    );
    expect(EventManifestCodec.decode(tampered)!.signatureValid, isFalse);
  });
}
