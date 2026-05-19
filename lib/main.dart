import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Screens
import 'package:smartbudget/screen/add_transaction_screen.dart';
import 'package:smartbudget/screen/profile_screen.dart';
import 'package:smartbudget/screen/history_screen.dart';
import 'package:smartbudget/screen/dashboard_screen.dart';
import 'package:smartbudget/view/auth/login_screen.dart';
import 'package:smartbudget/view/auth/signup_screen.dart';
import 'package:smartbudget/screen/notifications_screen.dart';
import 'package:smartbudget/screen/monthly_budget_screen.dart';
import 'package:smartbudget/screen/ai_assistant_screen.dart';
import 'package:smartbudget/screen/subscriptions_screen.dart';

// Controllers
import 'package:smartbudget/controllers/login_controller.dart';
import 'package:smartbudget/controllers/singup_controller.dart';
import 'package:smartbudget/controllers/dashboard_controller.dart';
import 'package:smartbudget/controllers/budget_controller.dart';
import 'package:smartbudget/controllers/profile_controler.dart';
import 'services/translation_service.dart';
import 'package:smartbudget/controllers/ai_controller.dart';
import 'package:smartbudget/controllers/subscription_controller.dart';
// Services
import 'package:smartbudget/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الخدمات بالترتيب الصحيح
  await Firebase.initializeApp();
  await GetStorage.init();
  await NotificationService().init();

  // حقن الكنترولرز قبل تشغيل التطبيق
  Get.lazyPut(() => DashboardController(), fenix: true);
  Get.lazyPut(() => BudgetController(), fenix: true);
  Get.lazyPut(() => ProfileController(), fenix: true);
  Get.lazyPut(() => SubscriptionController(), fenix: true);
  Get.lazyPut(() => AIController(), fenix: true);

  // تحديد المسار الابتدائي
  String startRoute = '/login';
  if (FirebaseAuth.instance.currentUser != null) {
    startRoute = '/home';
  }

  runApp(SmartBudgetApp(initialRoute: startRoute));
}

class SmartBudgetApp extends StatelessWidget {
  final String initialRoute;
  const SmartBudgetApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    // استرجاع الإعدادات
    bool isDark = box.read('isDarkMode') ?? false;
    String lang = box.read('lang') ?? 'en';

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Budget Pro',

      // إعدادات اللغة
      // translations: TranslationService(),
      locale: lang == 'ar' ? const Locale('ar', 'SA') : const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // إعدادات الثيم
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF103667),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      // تعريف المسارات
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/signup', page: () => SignUpPage()),
        GetPage(name: '/home', page: () => DashboardScreen()),
        GetPage(name: '/add-transaction', page: () => const AddTransactionScreen()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(name: '/history', page: () => const HistoryScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
        GetPage(name: '/monthly-budget', page: () => const MonthlyBudgetScreen()),
        GetPage(name: '/ai-assistant', page: () => const AIAssistantScreen()),
      ],
    );
  }
}