/// Public trust anchor for the explicitly local-development authority signer.
///
/// Local EventManifests include this value before they are HMAC-protected and
/// shared by QR. Production manifests must instead be issued with the public
/// key for the deployment-specific signing key.
abstract final class DevelopmentAuthorityTrust {
  static const keyId = 'meshsetu-authority-dev-v1';

  static const publicKeyJwk = <String, String>{
    'kty': 'EC',
    'crv': 'P-256',
    'x': 'sPFdOd84-QAzn084ou-s7xyKKvYo6_K6wOOjcjLbPRw',
    'y': 'M6Sc8H_oAneoBDAdYZUU_CtcaMB_z3vourkslIQ9DDk',
  };
}
