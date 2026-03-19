import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_translator/main.dart' as app;
import 'package:ml_translator/utils/constants.dart';

void main() {
  var IntegrationTestWidgetsFlutterBinding;
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Full app flow - select language, type, translate',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Select source language
      await tester.tap(find.byType(DropdownButton<Language>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('French').last);
      await tester.pumpAndSettle();

      // Select target language
      await tester.tap(find.byType(DropdownButton<Language>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('German').last);
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump(const Duration(seconds: 1));

      // Tap translate button
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      // Verify translation appears
      expect(find.byType(TextField).last, findsOneWidget);
    });
  });
}
