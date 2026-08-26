import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'stt_engine.dart';
import 'stt_model_manager.dart';

final class SherpaOnnxMultilingualSttEngine implements OfflineSttEngine {
  SherpaOnnxMultilingualSttEngine({required this.modelManager});

  final SttModelManager modelManager;

  sherpa_onnx.OfflineRecognizer? _recognizer;
  SttLanguage? _recognizerLanguage;

  @override
  Future<void> warmUp({SttLanguage language = SttLanguage.english}) async {
    if (_recognizer != null && _recognizerLanguage == language) return;

    sherpa_onnx.initBindings();
    // A recognizer owns its model and tokenizer natively. Release the old
    // language before opening another one so a changed profile can never
    // continue decoding through the previous language's recognizer.
    _recognizer?.free();
    _recognizer = null;
    _recognizerLanguage = null;
    final model = await _modelConfig(language);

    _recognizer = sherpa_onnx.OfflineRecognizer(
      sherpa_onnx.OfflineRecognizerConfig(model: model),
    );
    _recognizerLanguage = language;
  }

  @override
  Future<SttResult> transcribe(
    Uint8List pcm16le, {
    int sampleRateHz = 16000,
    SttLanguage language = SttLanguage.english,
  }) async {
    await warmUp(language: language);
    if (pcm16le.isEmpty) {
      throw StateError('sherpa-onnx received empty PCM input');
    }

    final recognizer = _recognizer;
    if (recognizer == null) {
      throw StateError('sherpa-onnx recognizer was not initialized');
    }

    final samples = pcm16leToFloat32Samples(pcm16le);
    final stream = recognizer.createStream();
    final stopwatch = Stopwatch()..start();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: sampleRateHz);
      recognizer.decode(stream);
      final result = recognizer.getResult(stream);
      stopwatch.stop();
      return SttResult(
        text: validateSttTranscriptScript(result.text, language),
        confidence: 0.0,
        inferenceMs: stopwatch.elapsedMilliseconds,
        modelId: 'nemo-ctc:${language.code}',
      );
    } finally {
      stream.free();
    }
  }

  @override
  Future<void> close() async {
    _recognizer?.free();
    _recognizer = null;
    _recognizerLanguage = null;
  }

  Future<sherpa_onnx.OfflineModelConfig> _modelConfig(
    SttLanguage language,
  ) async {
    final files = await modelManager.filesFor(language);
    return sherpa_onnx.OfflineModelConfig(
      nemoCtc: sherpa_onnx.OfflineNemoEncDecCtcModelConfig(
        model: files.model.path,
      ),
      tokens: files.tokens.path,
      numThreads: 2,
      debug: false,
      provider: 'cpu',
    );
  }
}

Float32List pcm16leToFloat32Samples(Uint8List pcm16le) {
  if (pcm16le.length.isOdd) {
    throw ArgumentError('pcm16le byte length must be even');
  }
  final input = ByteData.sublistView(pcm16le);
  final out = Float32List(pcm16le.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    final sample = input.getInt16(i * 2, Endian.little);
    out[i] = sample / 32768.0;
  }
  return out;
}

final _devanagariOnly = RegExp(
  r'^[\u0900-\u097F\uA8E0-\uA8FF0-9\s.,!?…:;()\-—]+$',
);
final _gujaratiOnly = RegExp(
  r'^[\u0A80-\u0AFF\u0964\u09650-9\s.,!?…:;()\-—]+$',
);
final _bengaliAssameseOnly = RegExp(
  r'^[\u0980-\u09FF\u0964\u09650-9\s.,!?…:;()\-—]+$',
);
final _kannadaOnly = RegExp(r'^[\u0C80-\u0CFF0-9\s.,!?…:;()\-—]+$');
final _malayalamOnly = RegExp(r'^[\u0D00-\u0D7F0-9\s.,!?…:;()\-—]+$');
final _gurmukhiOnly = RegExp(r'^[\u0A00-\u0A7F0-9\s.,!?…:;()\-—]+$');
final _tamilOnly = RegExp(r'^[\u0B80-\u0BFF0-9\s.,!?…:;()\-—]+$');
final _teluguOnly = RegExp(r'^[\u0C00-\u0C7F0-9\s.,!?…:;()\-—]+$');

/// Refuses to insert a transcript in an unexpected script. This is a safety
/// check, not a transliteration step: altering an Urdu transcript would make
/// an emergency description less reliable.
String validateSttTranscriptScript(String value, SttLanguage language) {
  var text = value.trim();
  if (language == SttLanguage.gujarati) {
    text = _devanagariToGujarati(text);
  }
  final pattern = switch (language) {
    SttLanguage.english => null,
    SttLanguage.hindi || SttLanguage.marathi => _devanagariOnly,
    SttLanguage.gujarati => _gujaratiOnly,
    SttLanguage.assamese || SttLanguage.bengali => _bengaliAssameseOnly,
    SttLanguage.kannada => _kannadaOnly,
    SttLanguage.malayalam => _malayalamOnly,
    SttLanguage.punjabi => _gurmukhiOnly,
    SttLanguage.tamil => _tamilOnly,
    SttLanguage.telugu => _teluguOnly,
  };
  if (text.isNotEmpty && pattern != null && !pattern.hasMatch(text)) {
    final requiredScript = switch (language) {
      SttLanguage.hindi || SttLanguage.marathi => 'Devanagari',
      SttLanguage.gujarati => 'Gujarati',
      SttLanguage.assamese || SttLanguage.bengali => 'Bengali-Assamese',
      SttLanguage.kannada => 'Kannada',
      SttLanguage.malayalam => 'Malayalam',
      SttLanguage.punjabi => 'Gurmukhi',
      SttLanguage.tamil => 'Tamil',
      SttLanguage.telugu => 'Telugu',
      SttLanguage.english => 'Latin',
    };
    throw StateError(
      '${language.displayName} voice input must be in $requiredScript script. '
      'Please record it again.',
    );
  }
  return text;
}

/// Gujarati and Devanagari place their equivalent letters at matching Unicode
/// offsets. A Gujarati model can occasionally emit the Devanagari glyphs for
/// otherwise correct Gujarati text; normalize only that script before the
/// Gujarati-only safety check.
String _devanagariToGujarati(String text) => String.fromCharCodes(
  text.runes.map(
    (rune) =>
        (rune >= 0x0900 && rune <= 0x0963) || (rune >= 0x0966 && rune <= 0x097f)
        ? rune + 0x0180
        : rune,
  ),
);
