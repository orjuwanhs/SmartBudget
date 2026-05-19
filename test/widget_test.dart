import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smartbudget/main.dart';

void main() {
  testWidgets('App smoke test - Login screen loads', (WidgetTester tester) async {
    // 1. تهيئة GetStorage للاختبار
    GetStorage.init();

    // 2. بناء التطبيق وتمرير المسار الابتدائي
    // قمنا بتمرير '/login' لأن الكلاس أصبح يتطلب initialRoute
    await tester.pumpWidget(const SmartBudgetApp(initialRoute: '/login'));

    // 3. التحقق من وجود نصوص تدل على صفحة تسجيل الدخول
    // بما أننا استخدمنا 'Smart Budget' في الهيدر، سنبحث عنه
    expect(find.textContaining('Smart'), findsOneWidget);
    expect(find.textContaining('Budget'), findsOneWidget);

    // 4. التحقق من وجود زر الدخول
    expect(find.text('LOGIN'), findsOneWidget);
  });
}