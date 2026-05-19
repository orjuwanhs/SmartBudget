import 'package:flutter/material.dart';

class AppBackgroundLayout extends StatelessWidget {
  final Widget child;

  const AppBackgroundLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الـ Stack يضمن بقاء الصورة في الخلف والعناصر فوقها
      body: Stack(
        children: [
          // عرض الصورة الأصلية كخلفية ثابتة
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.jpg',
              fit: BoxFit.cover, // لملء الشاشة بالكامل
            ),
          ),
          // طبقة شفافة اختيارية لجعل النصوص أكثر وضوحاً
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
          // المحتوى البرمجي للصفحة
          SafeArea(child: child),
        ],
      ),
    );
  }
}