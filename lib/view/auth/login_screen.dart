import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../controllers/login_controller.dart';
import '../../view/auth/signup_screen.dart';
import '../../view/auth/forgot_password_page.dart';
import 'package:smartbudget/controllers/profile_controler.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController authController = Get.put(LoginController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ألوان المشروع الموحدة
  static const Color deepBlue = Color(0xFF103667);
  static const Color deepTeal = Color(0xFF00796B);
  static const Color appGreen = Color(0xFF43A047); // الأخضر الأساسي
  static const Color lightGreen = Color(0xFF81C784); // أخضر فاتح للتدرج
  static const Color bgLight = Color(0xFFF8FAFC);

  // دالة لجعل الحجم متجاوباً
  double _getResponsiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;
    return size * (width / 400);
  }

  void _playClickSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // الفقاعات الخلفية لتوحيد التصميم مع الـ Dashboard
          Positioned(top: -50, right: -50, child: _buildBlurBlob([deepTeal.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.1)])),
          Positioned(bottom: -50, left: -50, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.1)])),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 25)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopHeader(context),
                    SizedBox(height: _getResponsiveSize(context, 30)),

                    // صندوق تسجيل الدخول الزجاجي المحسن
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(_getResponsiveSize(context, 25)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(30),
                            // إضافة إطار أخضر خفيف ليبرز الصندوق
                            border: Border.all(color: appGreen.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: appGreen.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.psychology_outlined, size: 50, color: appGreen),
                              SizedBox(height: _getResponsiveSize(context, 25)),

                              _buildTextField(
                                context,
                                hint: "Email Address",
                                icon: Icons.alternate_email_rounded,
                                controller: emailController,
                              ),
                              SizedBox(height: _getResponsiveSize(context, 15)),

                              _buildPasswordField(context, controller: passwordController),

                              SizedBox(height: _getResponsiveSize(context, 25)),

                              // صف يحتوي على زر الدخول وزر البصمة
                              Row(
                                children: [
                                  Expanded(child: _buildLoginButton(context)),
                                  const SizedBox(width: 12),
                                  _buildBiometricButton(context),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 30)),
                    _buildFooterSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 32),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            children: const [
              TextSpan(text: "Smart ", style: TextStyle(color: deepBlue)),
              TextSpan(text: "Budget", style: TextStyle(color: appGreen)),
            ],
          ),
        ),
        Text(
          "Manage your finances intelligently",
          style: TextStyle(
            color: Colors.black38,
            fontSize: _getResponsiveSize(context, 12),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, {required String hint, required IconData icon, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // إضافة إطار أخضر فاتح للحقول
        border: Border.all(color: appGreen.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
          // تغيير لون الأيقونة للأخضر ليتناسق مع الإطار
          prefixIcon: Icon(icon, color: appGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            // إضافة إطار أخضر فاتح لحقل كلمة المرور
            border: Border.all(color: appGreen.withOpacity(0.2), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: Obx(() => TextField(
            controller: controller,
            obscureText: !authController.isPasswordVisible.value,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
              // تغيير لون الأيقونة للأخضر ليتناسق مع الإطار
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: appGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  authController.isPasswordVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.black26, size: 18,
                ),
                onPressed: () => authController.isPasswordVisible.toggle(),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          )),
        ),
        TextButton(
          onPressed: () {
            _playClickSound();
            Get.to(() => ForgotPasswordPage(), transition: Transition.fade);
          },
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: deepTeal, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ويدجت زر البصمة الجديد
  Widget _buildBiometricButton(BuildContext context) {
    return Container(
      height: _getResponsiveSize(context, 55),
      width: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: appGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: const Icon(Icons.fingerprint_rounded, color: appGreen, size: 30),
        onPressed: () {
          _playClickSound();
          authController.loginWithBiometric(); // استدعاء دالة البصمة من الكنترولر
        },
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        // استخدام تدرج أخضر ملكي للأزرار ليتوافق مع الهوية
        gradient: const LinearGradient(colors: [appGreen, Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: authController.isLoading.value ? null : () {
          _playClickSound();
          authController.login(emailController.text, passwordController.text);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: authController.isLoading.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
          "LOGIN",
          style: TextStyle(
            color: Colors.white,
            fontSize: _getResponsiveSize(context, 16),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ));
  }

  Widget _buildFooterSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.black38, fontSize: 13)),
        GestureDetector(
          onTap: () {
            _playClickSound();
            Get.to(() => SignUpPage(), transition: Transition.rightToLeft);
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: appGreen, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 200, height: 200,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 80, spreadRadius: 40)]
      )
  );
}