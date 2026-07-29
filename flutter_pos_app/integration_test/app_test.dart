import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_pos_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('اختبارات التطبيق المتكاملة', () {
    testWidgets('شاشة الدخول تحتوي على جميع العناصر', (tester) async {
      await tester.pumpWidget(const app.ZimamPosApp());
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('اسم المستخدم'), findsOneWidget);
      expect(find.text('دخول الكاشير'), findsOneWidget);
    });

    testWidgets('تسجيل الدخول يعمل', (tester) async {
      await tester.pumpWidget(const app.ZimamPosApp());
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'كلمة المرور');
      expect(passwordField, findsOneWidget);

      await tester.enterText(passwordField, 'admin123');
      await tester.tap(find.text('دخول الكاشير'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('مرحباً بك'), findsWidgets);
    });

    testWidgets('زر التنبيهات يظهر بعد تسجيل الدخول', (tester) async {
      await tester.pumpWidget(const app.ZimamPosApp());
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'كلمة المرور');
      await tester.enterText(passwordField, 'admin123');
      await tester.tap(find.text('دخول الكاشير'));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('عناصر السرعة تظهر في لوحة التحكم', (tester) async {
      await tester.pumpWidget(const app.ZimamPosApp());
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextField, 'كلمة المرور');
      await tester.enterText(passwordField, 'admin123');
      await tester.tap(find.text('دخول الكاشير'));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      expect(find.text('الكاشير'), findsWidgets);
      expect(find.text('الطلبات'), findsWidgets);
      expect(find.text('المخزون'), findsWidgets);
    });
  });
}
