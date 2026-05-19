import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../thems/app_theme.dart';
import '../../controllers/login_controller.dart';

class NewPasswordPage extends StatelessWidget {
  NewPasswordPage({super.key});

  final LoginController authController = Get.find<LoginController>();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  // الألوان الموحدة للهوية البصرية
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
          // النمط البصري الموحد (الفقاعات العائمة)
          Positioned(top: -50, left: -50, child: _buildBlurBlob([appGreen.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.05)])),
          Positioned(bottom: -50, right: -50, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.05)])),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 25)),
                child: Column(
                  children: [
                    // أيقونة المفتاح العلوية بتصميم متناسق
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
                              _buildBrandHeader(context),
                              SizedBox(height: _getResponsiveSize(context, 25)),

                              // حقل كلمة المرور الجديدة
                              Obx(() => _buildPasswordField(
                                context,
                                hint: "New Password",
                                icon: Icons.lock_outline_rounded,
                                controller: newPassController,
                                isVisible: authController.isPasswordVisible.value,
                                onToggle: () => authController.togglePasswordVisibility(),
                              )),

                              SizedBox(height: _getResponsiveSize(context, 15)),

                              // حقل تأكيد كلمة المرور
                              Obx(() => _buildPasswordField(
                                context,
                                hint: "Confirm Password",
                                icon: Icons.lock_reset_rounded,
                                controller: confirmPassController,
                                isVisible: authController.isPasswordVisible.value,
                                onToggle: () => authController.togglePasswordVisibility(),
                              )),

                              SizedBox(height: _getResponsiveSize(context, 35)),

                              // زر التحديث بالتدرج الأخضر
                              _buildSubmitButton(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 20)),
                    _buildCancelFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, {
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: appGreen.withOpacity(0.2), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 13, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: appGreen, size: 22),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: Colors.black26, size: 20),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [appGreen, Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: () {
          _playClickSound();
          if (newPassController.text.isNotEmpty && newPassController.text == confirmPassController.text) {
            Get.snackbar("Done!", "Password updated successfully",
                backgroundColor: deepBlue, colorText: Colors.white, snackPosition: SnackPosition.TOP);
            Get.offAllNamed('/Login');
          } else {
            Get.snackbar("Error", "Passwords do not match",
                backgroundColor: Colors.redAccent, colorText: Colors.white);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("UPDATE PASSWORD", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: const Icon(Icons.vpn_key_rounded, size: 40, color: appGreen),
  );

  Widget _buildBrandHeader(BuildContext context) => Column(
    children: const [
      Text("Secure Access", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: deepBlue)),
      SizedBox(height: 8),
      Text("Set a strong password for your account", style: TextStyle(color: Colors.black38, fontSize: 12)),
    ],
  );

  Widget _buildCancelFooter() => TextButton(
    onPressed: () => Get.back(),
    child: const Text("Cancel & Go Back", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600)),
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