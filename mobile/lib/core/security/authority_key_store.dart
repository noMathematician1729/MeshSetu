import 'package:cryptography/cryptography.dart';

import '../../feature/join/manifest.dart';
import '../protocol/authority_signature.dart';

/// Trust boundary for sender-side authority responses. It never accepts a
/// key supplied by the response itself; the active authenticated manifest is
/// the only source of trust material.
final class AuthorityKeyStore {
  const AuthorityKeyStore();

  EcPublicKey? resolve({
    required EventManifest manifest,
    required String keyId,
  }) {
    if (keyId.isEmpty || keyId != manifest.authorityKeyId) return null;
    final jwk = manifest.authorityPublicKeyJwk;
    if (jwk == null) return null;
    try {
      return AuthorityPublicKeyJwk.fromJson(jwk).toEcPublicKey();
    } catch (_) {
      return null;
    }
  }
}
