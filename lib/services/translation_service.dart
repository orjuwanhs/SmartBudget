import 'package:get/get.dart';

class TranslationService extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'settings': 'Settings',
      'biometric': 'Biometric Security',
    },
    'ar_SA': {
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'settings': 'الإعدادات',
      'biometric': 'الأمان ببصمة الإصبع',
    }
  };
}