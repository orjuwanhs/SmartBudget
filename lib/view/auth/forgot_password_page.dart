import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../thems/app_theme.dart';
import '../../controllers/login_controller.dart';

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  // استدعاء الكنترولر الموجود مسبقاً في الذاكرة
  final LoginController authController = Get.find<LoginController>();
  final TextEditingController phoneController = TextEditingController();

  // الألوان الموحدة للمشروع
  static const Color deepBlue = Color(0xFF103667);
  static const Color appGreen = Color(0xFF43A047);
  static const Color bgLight = Color(0xFFF8FAFC);

  void _playClickSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  double _getResponsiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;
    return size * (width / 400);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // الفقاعات الخلفية لتوحيد النمط البصري
          Positioned(top: -40, right: -40, child: _buildBlurBlob([appGreen.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.05)])),
          Positioned(bottom: 20, left: -60, child: _buildBlurBlob([deepBlue.withOpacity(0.1), Colors.blue.shade900.withOpacity(0.05)])),

          SafeArea(
            child: Column(
              children: [
                // زر الرجوع بتصميم أنيق
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: deepBlue, size: 22),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 25)),
                      child: Column(
                        children: [
                          // صندوق استعادة كلمة المرور الزجاجي بإطار أخضر
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: EdgeInsets.all(_getResponsiveSize(context, 25)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(35),
                                  // الإطار الأخضر المميز
                                  border: Border.all(color: appGreen.withOpacity(0.3), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: appGreen.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // أيقونة الهاتف بتصميم عصري
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: appGreen.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.phonelink_lock_rounded, size: 55, color: appGreen),
                                    ),
                                    SizedBox(height: _getResponsiveSize(context, 20)),

                                    const Text(
                                      "Forgot Password?",
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: deepBlue, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Enter your registered phone number to receive a verification code (OTP).",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.black45, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: _getResponsiveSize(context, 30)),

                                    // حقل رقم الهاتف المحدث
                                    _buildPhoneField(context),

                                    SizedBox(height: _getResponsiveSize(context, 30)),

                                    // زر الإرسال بالتدرج الأخضر
                                    _buildSubmitButton(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 25)),

                          // نص توضيحي سفلي
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.info_outline_rounded, size: 14, color: appGreen),
                              SizedBox(width: 8),
                              Text(
                                "Use country code (e.g., +966)",
                                style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // إطار أخضر خفيف متناسق
        border: Border.all(color: appGreen.withOpacity(0.25), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: const InputDecoration(
          hintText: "+966 5xx xxx xxx",
          hintStyle: TextStyle(color: Colors.black26, fontWeight: FontWeight.normal, fontSize: 14),
          prefixIcon: Icon(Icons.phone_android_rounded, color: appGreen, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        // التدرج الأخضر الموحد للمشروع
        gradient: const LinearGradient(
          colors: [appGreen, Color(0xFF2E7D32)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: authController.isLoading.value
            ? null
            : () {
          _playClickSound();
          authController.sendOtp(phoneController.text);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: authController.isLoading.value
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.vibration_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
                "SEND CODE",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 100, spreadRadius: 50)]
      )
  );
}