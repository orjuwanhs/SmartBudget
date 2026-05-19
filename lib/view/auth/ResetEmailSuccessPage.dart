import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../thems/app_theme.dart';
import '../../controllers/login_controller.dart';
import 'new_password_page.dart';

class ResetEmailSuccessPage extends StatelessWidget {
  final String email;
  ResetEmailSuccessPage({super.key, required this.email});

  final LoginController authController = Get.find<LoginController>();
  final TextEditingController otpController = TextEditingController();

  // الألوان الموحدة
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
      body: Stack(
        children: [
          // النمط البصري الموحد
          Positioned(top: -50, right: -50, child: _buildBlurBlob([appGreen.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.05)])),
          Positioned(bottom: -50, left: -50, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.05)])),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 25)),
                child: Column(
                  children: [
                    // أيقونة التحقق العلوية
                    _buildTopIcon(context),
                    SizedBox(height: _getResponsiveSize(context, 20)),

                    // الصندوق الزجاجي بإطار أخضر ناعم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.all(_getResponsiveSize(context, 25)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: appGreen.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: appGreen.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildHeaderSection(context),
                              SizedBox(height: _getResponsiveSize(context, 25)),

                              // قسم العداد الزمني المطور
                              _buildTimerSection(context),

                              SizedBox(height: _getResponsiveSize(context, 20)),

                              // حقل إدخال الكود المنسق
                              _buildOTPField(context),

                              SizedBox(height: _getResponsiveSize(context, 30)),

                              // زر التحقق بالتدرج الأخضر
                              _buildVerifyButton(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 20)),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) => Column(
    children: [
      const Text("Verification", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: deepBlue, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.black45, fontSize: 13, height: 1.5),
          children: [
            const TextSpan(text: "Enter the 6-digit code sent to\n"),
            TextSpan(text: email, style: const TextStyle(color: deepBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  );

  Widget _buildTimerSection(BuildContext context) {
    return Obx(() {
      final bool isExpired = authController.isCodeExpired.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isExpired ? Colors.red.withOpacity(0.05) : appGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                    size: 16, color: isExpired ? Colors.redAccent : appGreen),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? "Code Expired"
                      : "Expires in: ${authController.timeLeft.value ~/ 60}:${(authController.timeLeft.value % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                      color: isExpired ? Colors.redAccent : deepBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14),
                ),
              ],
            ),
            if (isExpired)
              TextButton(
                onPressed: () {
                  _playClickSound();
                  authController.sendOtp(email);
                },
                child: const Text("Resend New Code", style: TextStyle(color: appGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              )
          ],
        ),
      );
    });
  }

  Widget _buildOTPField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: appGreen.withOpacity(0.2), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: TextField(
        controller: otpController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 10, color: deepBlue),
        decoration: const InputDecoration(
          hintText: "000000",
          hintStyle: TextStyle(color: Colors.black12, letterSpacing: 10),
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [appGreen, Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: authController.isLoading.value || authController.isCodeExpired.value
            ? null
            : () async {
          _playClickSound();
          bool success = await authController.verifyOtp(otpController.text);
          if (success) {
            Get.to(() => NewPasswordPage());
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: authController.isLoading.value
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("VERIFY NOW", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    ));
  }

  Widget _buildTopIcon(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: const Icon(Icons.mark_email_unread_rounded, size: 40, color: appGreen),
  );

  Widget _buildFooter(BuildContext context) => TextButton(
    onPressed: () => Get.back(),
    child: const Text("Change Email/Phone?", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600)),
  );

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 100, spreadRadius: 50)]
      )
  );
}