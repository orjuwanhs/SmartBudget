import 'package:flutter/material.dart';

class AppStyles {
  // الألوان الأساسية للثيم المعتمد
  static const Color grad1 = Color(0xFFD1E9F6); // أزرق فاتح
  static const Color grad2 = Color(0xFFA7EBC1); // أخضر مائي
  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color textColor = Color(0xFF1B3D4D);

  // التدرج اللوني للخلفية
  static const BoxDecoration mainBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [grad1, grad2],
    ),
  );

  // التدرج اللوني للأزرار (طلبك الأساسي)
  static const BoxDecoration buttonGradient = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(30)),
    gradient: LinearGradient(
      colors: [primaryTeal, darkTeal],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );

  // ستايل الحقول النصية (الزجاجي الأبيض)
  static InputDecoration glassInput(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: textColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}