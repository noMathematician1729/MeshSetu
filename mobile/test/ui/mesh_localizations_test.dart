import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/ui/localization/mesh_localizations.dart';

void main() {
  test('translates shared UI copy for every supported app language', () {
    expect(const MeshLocalizations(Locale('en')).text('Home'), 'Home');
    expect(const MeshLocalizations(Locale('hi')).text('Home'), 'होम');
    expect(const MeshLocalizations(Locale('mr')).text('Home'), 'मुख्यपृष्ठ');
    expect(const MeshLocalizations(Locale('gu')).text('Home'), 'હોમ');
    expect(const MeshLocalizations(Locale('bn')).text('Home'), 'হোম');
    expect(const MeshLocalizations(Locale('ta')).text('Home'), 'முகப்பு');
    expect(const MeshLocalizations(Locale('te')).text('Home'), 'హోమ్');
  });

  test('leaves dynamic user content unchanged', () {
    expect(
      const MeshLocalizations(Locale('hi')).text('Gate 2 needs help'),
      'Gate 2 needs help',
    );
  });
}
