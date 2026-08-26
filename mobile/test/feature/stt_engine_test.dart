import 'dart:typed_data';

import 'package:meshsetu_mobile/feature/stt/fake_stt_engine.dart';
import 'package:meshsetu_mobile/feature/stt/sherpa_onnx_stt_engine.dart';
import 'package:meshsetu_mobile/feature/stt/stt_engine.dart';
import 'package:test/test.dart';

void main() {
  test('SttLanguage recognizes the supported profile languages', () {
    expect(SttLanguage.fromDisplayName('English'), SttLanguage.english);
    expect(SttLanguage.fromDisplayName('Hindi'), SttLanguage.hindi);
    expect(SttLanguage.fromDisplayName('Marathi'), SttLanguage.marathi);
    expect(SttLanguage.fromDisplayName('Gujarati'), SttLanguage.gujarati);
    expect(SttLanguage.fromDisplayName('Kannada'), isNull);
  });

  test(
    'FakeOfflineSttEngine returns deterministic development output',
    () async {
      const engine = FakeOfflineSttEngine(
        transcript: 'help needed',
        confidence: 0.75,
        modelId: 'fake-test',
      );
      final result = await engine.transcribe(
        Uint8List.fromList(List<int>.filled(32000, 0)),
      );
      expect(result.text, 'help needed');
      expect(result.confidence, 0.75);
      expect(result.modelId, 'fake-test');
      expect(result.inferenceMs, greaterThan(0));
    },
  );

  test('Hindi and Marathi transcripts require Devanagari script', () {
    expect(
      validateSttTranscriptScript('मदद चाहिए', SttLanguage.hindi),
      'मदद चाहिए',
    );
    expect(
      () => validateSttTranscriptScript('مدد چاہیے', SttLanguage.hindi),
      throwsA(isA<StateError>()),
    );
  });

  test('Gujarati transcripts require Gujarati script', () {
    expect(
      validateSttTranscriptScript('મદદ જોઈએ', SttLanguage.gujarati),
      'મદદ જોઈએ',
    );
    expect(
      () => validateSttTranscriptScript('مدد چاہیے', SttLanguage.gujarati),
      throwsA(isA<StateError>()),
    );
  });

  test('Gujarati normalizes equivalent Devanagari characters', () {
    expect(
      validateSttTranscriptScript(
        'ગુજરાતી'.replaceAll('ગ', 'ग'),
        SttLanguage.gujarati,
      ),
      'ગુજરાતી',
    );
    expect(
      validateSttTranscriptScript('ગુજરાતી', SttLanguage.gujarati),
      'ગુજરાતી',
    );
  });
}
