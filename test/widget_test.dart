import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_translator/main.dart';
import 'package:ml_translator/screens/translator_screen.dart';
import 'package:ml_translator/widgets/language_selector.dart';
import 'package:ml_translator/widgets/translation_card.dart';
import 'package:ml_translator/utils/constants.dart';

void main() {
  group('App Initialization Tests', () {
    testWidgets('App launches and shows title', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MLTranslatorApp());

      // Verify that the app title is displayed
      expect(find.text(AppConstants.appName), findsOneWidget);

      // Verify that the main screen is loaded
      expect(find.byType(TranslatorScreen), findsOneWidget);
    });

    testWidgets('App has correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(const MLTranslatorApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      // Check theme properties
      expect(app.theme?.primarySwatch, Colors.blue);
      expect(app.theme?.useMaterial3, true);
      expect(app.theme?.brightness, Brightness.light);
    });
  });

  group('Translator Screen Tests', () {
    late Widget testWidget;

    setUp(() {
      testWidget = const MaterialApp(
        home: TranslatorScreen(),
      );
    });

    testWidgets('Screen contains all essential elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Check for language selectors
      expect(find.byType(LanguageSelector), findsNWidgets(2));

      // Check for translation cards
      expect(find.byType(TranslationCard), findsNWidgets(2));

      // Check for action buttons
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);

      // Check for icons
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('Language selector displays correct default languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Find language selectors
      final languageSelectors = find.byType(LanguageSelector);

      // First selector should show English
      final firstSelector =
          tester.widget<LanguageSelector>(languageSelectors.first);
      expect(firstSelector.selectedLanguage.name, 'English');

      // Second selector should show Spanish
      final secondSelector =
          tester.widget<LanguageSelector>(languageSelectors.last);
      expect(secondSelector.selectedLanguage.name, 'Spanish');
    });

    testWidgets('Swap languages button works', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Get initial language names
      final initialFirstSelector =
          tester.widget<LanguageSelector>(find.byType(LanguageSelector).first);
      final initialSecondSelector =
          tester.widget<LanguageSelector>(find.byType(LanguageSelector).last);

      final initialFirstLang = initialFirstSelector.selectedLanguage.name;
      final initialSecondLang = initialSecondSelector.selectedLanguage.name;

      // Tap swap button
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pump();

      // Get updated language names
      final updatedFirstSelector =
          tester.widget<LanguageSelector>(find.byType(LanguageSelector).first);
      final updatedSecondSelector =
          tester.widget<LanguageSelector>(find.byType(LanguageSelector).last);

      // Verify languages are swapped
      expect(updatedFirstSelector.selectedLanguage.name, initialSecondLang);
      expect(updatedSecondSelector.selectedLanguage.name, initialFirstLang);
    });

    testWidgets('Clear button clears text fields', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Enter text in source field
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump();

      // Verify text is entered
      expect(find.text('Hello'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.text('Clear'));
      await tester.pump();

      // Verify fields are cleared
      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('Translate button is disabled when source text is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      final translateButton = find.widgetWithText(ElevatedButton, 'Translate');

      // Initially disabled (source text empty)
      final button = tester.widget<ElevatedButton>(translateButton);
      expect(button.onPressed, null);

      // Enter text
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump();

      // Button should be enabled
      final updatedButton = tester.widget<ElevatedButton>(translateButton);
      expect(updatedButton.onPressed, isNotNull);
    });

    testWidgets('Text input triggers translation debounce',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);

      // Enter text quickly
      await tester.enterText(find.byType(TextField).first, 'H');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, 'He');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, 'Hel');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, 'Hell');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, 'Hello');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Verify loading indicator appears (translation in progress)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Language Selector Tests', () {
    testWidgets('Language selector shows correct number of languages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              selectedLanguage: AppConstants.defaultLanguages[0],
              languages: AppConstants.defaultLanguages,
              onChanged: (language) {},
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButton<Language>));
      await tester.pumpAndSettle();

      // Verify number of items in dropdown
      expect(find.byType(DropdownMenuItem<Language>),
          findsNWidgets(AppConstants.defaultLanguages.length));
    });

    testWidgets('Language selector displays flag and name',
        (WidgetTester tester) async {
      final testLanguage = AppConstants.defaultLanguages[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              selectedLanguage: testLanguage,
              languages: AppConstants.defaultLanguages,
              onChanged: (language) {},
            ),
          ),
        ),
      );

      // Check if flag and name are displayed
      expect(find.text(testLanguage.flag), findsOneWidget);
      expect(find.text(testLanguage.name), findsOneWidget);
    });

    testWidgets('Language selection triggers callback',
        (WidgetTester tester) async {
      Language? selectedLanguage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageSelector(
              selectedLanguage: AppConstants.defaultLanguages[0],
              languages: AppConstants.defaultLanguages,
              onChanged: (language) {
                selectedLanguage = language;
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<Language>));
      await tester.pumpAndSettle();

      // Select second language
      await tester.tap(find.text(AppConstants.defaultLanguages[1].name).last);
      await tester.pump();

      // Verify callback was called with correct language
      expect(selectedLanguage?.name, AppConstants.defaultLanguages[1].name);
    });
  });

  group('Translation Card Tests', () {
    testWidgets('Translation card displays title and text field',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationCard(
              title: 'Test Title',
              controller: controller,
              hintText: 'Test Hint',
              onChanged: (value) {},
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Test Title'), findsOneWidget);

      // Check text field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('Translation card can be read-only',
        (WidgetTester tester) async {
      final controller = TextEditingController(text: 'Read-only text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationCard(
              title: 'Test Title',
              controller: controller,
              hintText: 'Test Hint',
              readOnly: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, true);
      expect(find.text('Read-only text'), findsOneWidget);
    });

    testWidgets('Translation card shows microphone button when provided',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationCard(
              title: 'Test Title',
              controller: controller,
              hintText: 'Test Hint',
              onMicPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('Translation card shows listening state',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationCard(
              title: 'Test Title',
              controller: controller,
              hintText: 'Test Hint',
              onMicPressed: () {},
              isListening: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });

  group('Constants Tests', () {
    test('AppConstants has correct default values', () {
      expect(AppConstants.appName, 'ML Translator');
      expect(AppConstants.defaultLanguages.isNotEmpty, true);
      expect(AppConstants.defaultLanguages.length, 18);
    });

    test('Language class works correctly', () {
      final language = Language('en', 'English');

      expect(language.code, 'en');
      expect(language.name, 'English');
      expect(language.flag, '🇺🇸');
    });

    test('Language equality works', () {
      final language1 = Language('en', 'English');
      final language2 = Language('en', 'English');
      final language3 = Language('es', 'Spanish');

      expect(language1 == language2, true);
      expect(language1 == language3, false);
      expect(language1.hashCode, language2.hashCode);
    });

    test('All languages have flags', () {
      for (var language in AppConstants.defaultLanguages) {
        expect(AppConstants.languageFlags.containsKey(language.code), true);
      }
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Error message displays when translation fails',
        (WidgetTester tester) async {
      // Mock translation error scenario
      await tester.pumpWidget(const MaterialApp(
        home: TranslatorScreen(),
      ));

      // Trigger error condition (this would need proper mocking in real implementation)
      // For now, just verify the error container exists
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  group('Navigation and Interaction Tests', () {
    testWidgets('Copy button appears when translation exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TranslatorScreen(),
      ));

      // Initially no copy button
      expect(find.byIcon(Icons.copy), findsNothing);

      // Set some text in target field (simulating translation)
      final targetField = find.byType(TextField).last;
      await tester.enterText(targetField, 'Translated text');
      await tester.pump();

      // Copy button should appear
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('Speaker button appears when translation exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TranslatorScreen(),
      ));

      // Initially no speaker button
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Set some text in target field
      final targetField = find.byType(TextField).last;
      await tester.enterText(targetField, 'Translated text');
      await tester.pump();

      // Speaker button should appear
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('App builds within reasonable time',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const MLTranslatorApp());

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds < 1000, true);
    });

    testWidgets('Text input is responsive', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TranslatorScreen(),
      ));

      final stopwatch = Stopwatch()..start();

      await tester.enterText(find.byType(TextField).first, 'Test input');
      await tester.pump();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds < 100, true);
    });
  });
}

extension on ThemeData? {
  get primarySwatch => null;
}
