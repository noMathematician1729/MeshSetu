import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/security/authority_key_store.dart';
import 'package:meshsetu_mobile/core/security/development_authority_trust.dart';
import 'package:meshsetu_mobile/feature/join/join_repository.dart';
import 'package:meshsetu_mobile/feature/join/manifest.dart';
import 'package:test/test.dart';

void _expectDevelopmentTrust(Map<String, String>? publicKeyJwk) {
  expect(publicKeyJwk, isNotNull);
  expect(
    publicKeyJwk,
    hasLength(DevelopmentAuthorityTrust.publicKeyJwk.length),
  );
  for (final entry in DevelopmentAuthorityTrust.publicKeyJwk.entries) {
    expect(publicKeyJwk![entry.key], entry.value);
  }
}

void main() {
  test(
    'local event manifest pins and transports the development authority key',
    () async {
      final previousDatabaseWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousDatabaseWarningSetting,
      );
      final organizerDb = MeshDatabase.forTesting(NativeDatabase.memory());
      final participantDb = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(organizerDb.close);
      addTearDown(participantDb.close);

      final organizer = JoinRepository(organizerDb);
      final manifest = await organizer.createLocalEvent(siteName: 'Trust test');

      expect(manifest.authorityKeyId, DevelopmentAuthorityTrust.keyId);
      _expectDevelopmentTrust(manifest.authorityPublicKeyJwk);
      expect(
        AuthorityKeyStore().resolve(
          manifest: manifest,
          keyId: DevelopmentAuthorityTrust.keyId,
        ),
        isA<EcPublicKey>(),
      );

      final invite = EventManifestCodec.encode(manifest, roomId: 'public');
      final joined = await JoinRepository(
        participantDb,
      ).parseAndValidateQr(invite);
      expect(joined, isA<JoinOk>());

      final participantManifest = await JoinRepository(
        participantDb,
      ).activeManifest();
      expect(participantManifest?.siteId, manifest.siteId);
      expect(
        participantManifest?.authorityKeyId,
        DevelopmentAuthorityTrust.keyId,
      );
      _expectDevelopmentTrust(participantManifest?.authorityPublicKeyJwk);
      expect(
        AuthorityKeyStore().resolve(
          manifest: participantManifest!,
          keyId: DevelopmentAuthorityTrust.keyId,
        ),
        isA<EcPublicKey>(),
      );
    },
  );

  test(
    'backfills authority trust only for a legacy local event manifest',
    () async {
      final database = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = JoinRepository(database);
      await repository.activateManifest(
        const EventManifest(
          siteId: 'event-legacy',
          siteName: 'Legacy local event',
          meshCode: 'LOCAL-LEGACY',
          validFromMs: 0,
          validUntilMs: 9999999999999,
          gatewayHint: '',
          rooms: [],
        ),
      );

      final upgraded = await repository.activeManifest();
      expect(upgraded?.authorityKeyId, DevelopmentAuthorityTrust.keyId);
      _expectDevelopmentTrust(upgraded?.authorityPublicKeyJwk);

      await repository.activateManifest(
        const EventManifest(
          siteId: 'external-event',
          siteName: 'External event',
          meshCode: 'EXTERNAL',
          validFromMs: 0,
          validUntilMs: 9999999999999,
          gatewayHint: '',
          rooms: [],
        ),
      );
      final untrusted = await repository.activeManifest();
      expect(untrusted?.authorityKeyId, isEmpty);
      expect(untrusted?.authorityPublicKeyJwk, isNull);
    },
  );

  test(
    'renews an expired locally-issued event instead of losing authority trust',
    () async {
      final database = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = JoinRepository(database);
      final now = DateTime.now().millisecondsSinceEpoch;
      // Reproduces the field failure: a LOCAL- event created ~28h earlier
      // with the legacy 24h window, already past validUntilMs.
      await repository.activateManifest(
        EventManifest(
          siteId: 'event-1787668838661-1eth0zt',
          siteName: 'Field test event',
          meshCode: 'LOCAL-1ETH0ZT',
          validFromMs: now - const Duration(hours: 28).inMilliseconds,
          validUntilMs: now - const Duration(hours: 4).inMilliseconds,
          gatewayHint: '',
          authorityKeyId: DevelopmentAuthorityTrust.keyId,
          authorityPublicKeyJwk: DevelopmentAuthorityTrust.publicKeyJwk,
          rooms: const [],
        ),
      );

      final renewed = await repository.activeManifest();
      expect(
        renewed,
        isNotNull,
        reason: 'a local event must self-heal, not vanish',
      );
      expect(renewed!.siteId, 'event-1787668838661-1eth0zt');
      expect(renewed.validUntilMs, greaterThan(now));
      expect(renewed.authorityKeyId, DevelopmentAuthorityTrust.keyId);
      _expectDevelopmentTrust(renewed.authorityPublicKeyJwk);
      expect(
        AuthorityKeyStore().resolve(
          manifest: renewed,
          keyId: DevelopmentAuthorityTrust.keyId,
        ),
        isA<EcPublicKey>(),
      );
    },
  );

  test(
    'does not renew an externally issued manifest past its expiry',
    () async {
      final database = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = JoinRepository(database);
      final now = DateTime.now().millisecondsSinceEpoch;
      await repository.activateManifest(
        EventManifest(
          siteId: 'external-event',
          siteName: 'External event',
          meshCode: 'EXTERNAL',
          validFromMs: now - const Duration(hours: 28).inMilliseconds,
          validUntilMs: now - const Duration(hours: 4).inMilliseconds,
          gatewayHint: '',
          authorityKeyId: DevelopmentAuthorityTrust.keyId,
          authorityPublicKeyJwk: DevelopmentAuthorityTrust.publicKeyJwk,
          rooms: const [],
        ),
      );

      expect(await repository.activeManifest(), isNull);
    },
  );
}
