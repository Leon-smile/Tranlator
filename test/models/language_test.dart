import 'package:flutter_test/flutter_test.dart';
import 'package:ml_translator/utils/constants.dart';

void main() {
  group('Language Model Tests', () {
    test('Language constructor creates valid object', () {
      final language = Language('en', 'English');

      expect(language.code, 'en');
      expect(language.name, 'English');
    });

    test('Language flag returns correct emoji', () {
      final english = Language('en', 'English');
      final spanish = Language('es', 'Spanish');
      final unknown = Language('xx', 'Unknown');

      expect(english.flag, '🇺🇸');
      expect(spanish.flag, '🇪🇸');
      expect(unknown.flag, '🌐');
    });

    test('Language toString returns name', () {
      final language = Language('en', 'English');
      expect(language.toString(), 'English');
    });
  });
}
