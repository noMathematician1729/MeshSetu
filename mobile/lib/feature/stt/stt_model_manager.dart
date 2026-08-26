import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'stt_engine.dart';

typedef SttModelProgressCallback =
    void Function(SttModelDownloadProgress value);

final class SttModelDownloadProgress {
  const SttModelDownloadProgress({
    required this.completedBytes,
    required this.totalBytes,
  });

  final int completedBytes;
  final int totalBytes;

  double get fraction => totalBytes == 0 ? 0 : completedBytes / totalBytes;
}

final class SttModelFiles {
  const SttModelFiles({required this.model, required this.tokens});

  final File model;
  final File tokens;
}

final class SttModelManifest {
  const SttModelManifest({
    required this.language,
    required this.modelUrl,
    required this.modelSha256,
    required this.modelBytes,
    required this.tokensUrl,
    required this.tokensSha256,
    required this.tokensBytes,
  });

  final SttLanguage language;
  final Uri modelUrl;
  final String modelSha256;
  final int modelBytes;
  final Uri tokensUrl;
  final String tokensSha256;
  final int tokensBytes;

  int get totalBytes => modelBytes + tokensBytes;
}

const _revision = '2d3ac712ec3a672444297555208dd030060962e3';
const _repository =
    'https://huggingface.co/parismitaglobalsolutions/indicconformer-sherpa-onnx';
const _tokensSha256 =
    'ee60967630213f31951817ac8b402b92ec18cce80718a24a49b388e56672dfb2';
const _tokensBytes = 67605;

final _defaultManifests = <SttLanguage, SttModelManifest>{
  SttLanguage.english: SttModelManifest(
    language: SttLanguage.english,
    modelUrl: Uri.parse('$_repository/resolve/$_revision/en/model.int8.onnx'),
    modelSha256:
        '28b9261a53028a7c99ff0799f44fb53f19c78b68cc4cf40637ac9c16cb1fbc6f',
    modelBytes: 174610057,
    tokensUrl: Uri.parse('$_repository/resolve/$_revision/en/tokens.txt'),
    tokensSha256:
        '89c165b98df7af718ec0e872177279bfad4ade51331f1be92753c9583a1ef30d',
    tokensBytes: 11433,
  ),
  SttLanguage.hindi: _manifest(
    SttLanguage.hindi,
    197595593,
    '915c71e04dd7e5378a4057fdebb252b3a587188e4e99db6d7ce0909ad5ad05fa',
  ),
  SttLanguage.marathi: _manifest(
    SttLanguage.marathi,
    197595593,
    '1ea81e55c4b9b12624c9d02a5b9c1b6f7c871c78a55ff52d333f81cb5136eaf2',
  ),
  SttLanguage.gujarati: _manifest(
    SttLanguage.gujarati,
    197595461,
    '822ed7f0b809bbd479275bf91c913d05564b88c0d082bbcba2f37999b88cb598',
  ),
};

SttModelManifest _manifest(
  SttLanguage language,
  int modelBytes,
  String modelSha256,
) => SttModelManifest(
  language: language,
  modelUrl: Uri.parse(
    '$_repository/resolve/$_revision/${language.code}/model.int8.onnx',
  ),
  modelSha256: modelSha256,
  modelBytes: modelBytes,
  tokensUrl: Uri.parse('$_repository/resolve/$_revision/tokens.txt'),
  tokensSha256: _tokensSha256,
  tokensBytes: _tokensBytes,
);

/// Installs the Sherpa-ONNX-compatible model for a selected language.
final class SttModelManager {
  SttModelManager({
    http.Client? client,
    Future<Directory> Function()? applicationSupportDirectory,
    Map<SttLanguage, SttModelManifest>? manifests,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _applicationSupportDirectory =
           applicationSupportDirectory ?? getApplicationSupportDirectory,
       _manifests = manifests ?? _defaultManifests;

  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _applicationSupportDirectory;
  final Map<SttLanguage, SttModelManifest> _manifests;
  final Set<SttLanguage> _verified = {};
  final Map<SttLanguage, Future<void>> _downloads = {};

  Future<bool> isReady(SttLanguage language) async {
    final manifest = _manifests[language];
    if (manifest == null || _verified.contains(language)) return true;
    final files = await _filesFor(manifest);
    final ready =
        await _matchesHash(files.model, manifest.modelSha256) &&
        await _matchesHash(files.tokens, manifest.tokensSha256);
    if (ready) _verified.add(language);
    return ready;
  }

  Future<SttModelFiles> filesFor(SttLanguage language) async {
    final manifest = _manifests[language];
    if (manifest == null) {
      throw ArgumentError(
        '${language.displayName} has no configured voice model.',
      );
    }
    if (!await isReady(language)) {
      throw StateError(
        '${language.displayName} voice model is still downloading.',
      );
    }
    return _filesFor(manifest);
  }

  Future<void> download(
    SttLanguage language, {
    SttModelProgressCallback? onProgress,
  }) {
    final existing = _downloads[language];
    if (existing != null) return existing;
    final future = _download(language, onProgress: onProgress);
    _downloads[language] = future;
    return future.whenComplete(() => _downloads.remove(language));
  }

  Future<void> _download(
    SttLanguage language, {
    SttModelProgressCallback? onProgress,
  }) async {
    final manifest = _manifests[language];
    if (manifest == null || await isReady(language)) return;

    final files = await _filesFor(manifest);
    var completed = 0;
    if (await _matchesHash(files.tokens, manifest.tokensSha256)) {
      completed += manifest.tokensBytes;
    } else {
      await _downloadFile(
        url: manifest.tokensUrl,
        target: files.tokens,
        expectedBytes: manifest.tokensBytes,
        expectedSha256: manifest.tokensSha256,
        onBytes: (bytes) => onProgress?.call(
          SttModelDownloadProgress(
            completedBytes: bytes,
            totalBytes: manifest.totalBytes,
          ),
        ),
      );
      completed += manifest.tokensBytes;
    }

    if (!await _matchesHash(files.model, manifest.modelSha256)) {
      await _downloadFile(
        url: manifest.modelUrl,
        target: files.model,
        expectedBytes: manifest.modelBytes,
        expectedSha256: manifest.modelSha256,
        onBytes: (bytes) => onProgress?.call(
          SttModelDownloadProgress(
            completedBytes: completed + bytes,
            totalBytes: manifest.totalBytes,
          ),
        ),
      );
    }
    _verified.add(language);
    onProgress?.call(
      SttModelDownloadProgress(
        completedBytes: manifest.totalBytes,
        totalBytes: manifest.totalBytes,
      ),
    );
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<SttModelFiles> _filesFor(SttModelManifest manifest) async {
    final supportDirectory = await _applicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}/models/indicconformer-${manifest.language.code}',
    );
    await directory.create(recursive: true);
    return SttModelFiles(
      model: File('${directory.path}/model.int8.onnx'),
      tokens: File('${directory.path}/tokens.txt'),
    );
  }

  Future<void> _downloadFile({
    required Uri url,
    required File target,
    required int expectedBytes,
    required String expectedSha256,
    required void Function(int bytes) onBytes,
  }) async {
    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();

    try {
      final response = await _client.send(http.Request('GET', url));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Model download failed with HTTP ${response.statusCode}.',
        );
      }

      final digestSink = _DigestCollector();
      final digest = sha256.startChunkedConversion(digestSink);
      final output = partial.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          digest.add(chunk);
          output.add(chunk);
          onBytes(received);
        }
        await output.flush();
      } finally {
        await output.close();
        digest.close();
      }

      if (received != expectedBytes ||
          digestSink.value.toString() != expectedSha256) {
        throw StateError(
          'Downloaded voice model failed integrity verification.',
        );
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<bool> _matchesHash(File file, String expectedSha256) async {
    if (!await file.exists()) return false;
    final digestSink = _DigestCollector();
    final digest = sha256.startChunkedConversion(digestSink);
    await for (final chunk in file.openRead()) {
      digest.add(chunk);
    }
    digest.close();
    return digestSink.value.toString() == expectedSha256;
  }
}

final class _DigestCollector implements Sink<Digest> {
  Digest? _digest;

  Digest get value => _digest!;

  @override
  void add(Digest value) => _digest = value;

  @override
  void close() {}
}
