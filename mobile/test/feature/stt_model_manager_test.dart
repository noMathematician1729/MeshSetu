import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshsetu_mobile/feature/stt/stt_engine.dart';
import 'package:meshsetu_mobile/feature/stt/stt_model_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('meshsetu-stt-');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('downloads and verifies a Sherpa language model', () async {
    final model = <int>[1, 2, 3, 4];
    final tokens = <int>[5, 6, 7];
    final manager = SttModelManager(
      client: MockClient((request) async {
        if (request.url.path.endsWith('model.int8.onnx')) {
          return http.Response.bytes(model, 200);
        }
        return http.Response.bytes(tokens, 200);
      }),
      applicationSupportDirectory: () async => temporaryDirectory,
      manifests: {SttLanguage.hindi: _manifest(model, tokens)},
    );

    await manager.download(SttLanguage.hindi);

    expect(await manager.isReady(SttLanguage.hindi), isTrue);
    final files = await manager.filesFor(SttLanguage.hindi);
    expect(await files.model.readAsBytes(), model);
    expect(await files.tokens.readAsBytes(), tokens);
  });

  test('removes a partial download when verification fails', () async {
    final model = <int>[1, 2, 3, 4];
    final manifest = _manifest(model, <int>[5, 6, 7]);
    final manager = SttModelManager(
      client: MockClient(
        (_) async => http.Response.bytes(<int>[9, 9, 9, 9], 200),
      ),
      applicationSupportDirectory: () async => temporaryDirectory,
      manifests: {SttLanguage.hindi: manifest},
    );

    await expectLater(
      manager.download(SttLanguage.hindi),
      throwsA(isA<StateError>()),
    );

    final partial = File(
      '${temporaryDirectory.path}/models/indicconformer-hi/tokens.txt.part',
    );
    expect(await partial.exists(), isFalse);
  });
}

SttModelManifest _manifest(List<int> model, List<int> tokens) =>
    SttModelManifest(
      language: SttLanguage.hindi,
      modelUrl: Uri.parse('https://example.test/model.int8.onnx'),
      modelSha256: sha256.convert(model).toString(),
      modelBytes: model.length,
      tokensUrl: Uri.parse('https://example.test/tokens.txt'),
      tokensSha256: sha256.convert(tokens).toString(),
      tokensBytes: tokens.length,
    );
