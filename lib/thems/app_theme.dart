import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppStyles {
  // الألوان الأساسية
  static const Color primaryLightBlue = Color(0xFFD1E9F6);
  static const Color primaryLightGreen = Color(0xFFA7EBC1);
  static const Color darkTextColor = Color(0xFF1B3D4D);
  static const Color tealColor = Color(0xFF00897B);
  static const Color darkTealColor = Color(0xFF004D40);
  static const Color signUpTeal = Color(0xFF00796B);
  static const Color footerGrey = Color(0xFF455A64); // أضفنا هذا السطر لحل الخطأ الثاني


// 1. رسالة الخطأ - خلفية بيضاء زجاجية مع نصوص حمراء داكنة
  static void showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      // خلفية بيضاء داكنة (Off-White) شفافة قليلاً
      backgroundColor: Colors.white.withOpacity(0.7),
      margin: const EdgeInsets.all(15),
      borderRadius: 20,
      borderWidth: 1.5,
      // تحديد خفيف باللون الأحمر الباهت لتمييزها كرسالة خطأ
      borderColor: Colors.red.withOpacity(0.2),
      icon: const Icon(Icons.error_outline, color: Color(0xFFB71C1C), size: 32),
      duration: const Duration(seconds: 4),
      // وضوح عالي للعنوان
      titleText: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C), // أحمر داكن جداً
            fontSize: 16
        ),
      ),
      // وضوح عالي للمحتوى
      messageText: Text(
        message,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87, // أسود هادئ وواضح
            fontSize: 14
        ),
      ),
      barBlur: 15, // تأثير التغبيش الزجاجي
    );
  }

  // 2. رسالة النجاح - خلفية بيضاء زجاجية مع نصوص زرقاء داكنة
  static void showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white.withOpacity(0.7),
      margin: const EdgeInsets.all(15),
      borderRadius: 20,
      borderWidth: 1.5,
      // تحديد خفيف باللون الأزرق الباهت
      borderColor: Colors.blue.withOpacity(0.2),
      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF0D47A1), size: 32),
      duration: const Duration(seconds: 4),
      titleText: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1), // أزرق داكن جداً
            fontSize: 16
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14
        ),
      ),
      barBlur: 15,
    );
  }
  // الديكورات
  static BoxDecoration mainBackground() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primaryLightBlue, primaryLightGreen],
    ),
  );

  static BoxDecoration glassBoxDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.35),
    borderRadius: BorderRadius.circular(40),
    border: Border.all(
      color: Colors.white.withOpacity(0.5),
      width: 1.5,
    ),
  );

  static BoxDecoration inputFieldDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(30),
  );

  static BoxDecoration buttonGradientDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      colors: [tealColor, darkTealColor],
    ),
    boxShadow: [
      BoxShadow(
        color: darkTealColor.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      )
    ],
  );
}