import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../thems/app_theme.dart';
import '../../controllers/singup_controller.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final _formKey = GlobalKey<FormState>();

  final SignUpController authController = Get.put(SignUpController());
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // الألوان الموحدة للمشروع
  static const Color deepBlue = Color(0xFF103667);
  static const Color appGreen = Color(0xFF43A047);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color bgLight = Color(0xFFF8FAFC);

  void _playClickSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  // ميثود للحجم المتجاوب
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
          // الفقاعات الخلفية (نفس نمط اللوج ان)
          Positioned(top: -50, left: -50, child: _buildBlurBlob([appGreen.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.1)])),
          Positioned(bottom: -50, right: -50, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.1)])),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 25)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTopIcon(context),
                      SizedBox(height: _getResponsiveSize(context, 20)),
                      
                      // صندوق التسجيل الزجاجي المحسن بإطار أخضر
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.all(_getResponsiveSize(context, 22)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              // الإطار الأخضر المميز
                              border: Border.all(color: appGreen.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: appGreen.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildBrandText(context),
                                SizedBox(height: _getResponsiveSize(context, 15)),
                                
                                // حقل الاسم
                                _buildTextField(
                                  context,
                                  hint: "Full Name",
                                  icon: Icons.person_outline_rounded,
                                  controller: nameController,
                                  validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                                ),
                                SizedBox(height: _getResponsiveSize(context, 12)),

                                // حقل الايميل
                                _buildTextField(
                                  context,
                                  hint: "Email Address",
                                  icon: Icons.alternate_email_rounded,
                                  controller: emailController,
                                  validator: (value) {
                                    if (value!.isEmpty) return "Email is required";
                                    if (!GetUtils.isEmail(value)) return "Enter a valid email";
                                    return null;
                                  },
                                ),
                                SizedBox(height: _getResponsiveSize(context, 12)),

                                // حقل الهاتف
                                _buildTextField(
                                  context,
                                  hint: "Phone Number (05...)",
                                  icon: Icons.phone_android_rounded,
                                  controller: phoneController,
                                  isPhone: true,
                                  validator: (value) {
                                    if (value!.isEmpty) return "Phone number is required";
                                    if (!RegExp(r'^05[0-9]{8}$').hasMatch(value)) {
                                      return "Must start with 05 and be 10 digits";
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: _getResponsiveSize(context, 12)),

                                // حقل كلمة المرور
                                Obx(() => _buildTextField(
                                  context,
                                  hint: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  controller: passwordController,
                                  isPassword: !authController.isPasswordVisible.value,
                                  suffixIcon: IconButton(
                                    icon: Icon(authController.isPasswordVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.black26, size: 18),
                                    onPressed: () => authController.isPasswordVisible.toggle(),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) return "Password is required";
                                    if (value.length < 8) return "Must be at least 8 characters";
                                    return null;
                                  },
                                )),
                                SizedBox(height: _getResponsiveSize(context, 12)),

                                // حقل تأكيد كلمة المرور
                                Obx(() => _buildTextField(
                                  context,
                                  hint: "Confirm Password",
                                  icon: Icons.lock_reset_rounded,
                                  controller: confirmPasswordController,
                                  isPassword: !authController.isConfirmPasswordVisible.value,
                                  suffixIcon: IconButton(
                                    icon: Icon(authController.isConfirmPasswordVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.black26, size: 18),
                                    onPressed: () => authController.isConfirmPasswordVisible.toggle(),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) return "Please confirm password";
                                    if (value != passwordController.text) return "Passwords do not match";
                                    return null;
                                  },
                                )),

                                SizedBox(height: _getResponsiveSize(context, 25)),
                                _buildSignUpButton(context),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPhone = false,
    required TextEditingController controller,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // الإطار الأخضر الخفيف للحقول ليتناسب مع اللوج ان
        border: Border.all(color: appGreen.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
          prefixIcon: Icon(icon, color: appGreen, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
          errorStyle: const TextStyle(height: 0.8, color: Colors.redAccent, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      height: _getResponsiveSize(context, 55),
      decoration: BoxDecoration(
        // التدرج الأخضر الموحد
        gradient: const LinearGradient(colors: [appGreen, Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: appGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: authController.isLoading.value ? null : () {
          if (_formKey.currentState!.validate()) {
            _playClickSound();
            authController.signUp(
              email: emailController.text.trim(),
              password: passwordController.text,
              confirmPassword: confirmPasswordController.text,
              fullName: nameController.text.trim(),
              phone: phoneController.text.trim(),
            );
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        child: authController.isLoading.value
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    ));
  }

  Widget _buildBrandText(BuildContext context) => RichText(
    text: TextSpan(
      style: TextStyle(fontSize: _getResponsiveSize(context, 30), fontWeight: FontWeight.w900, letterSpacing: 1.0),
      children: const [
        TextSpan(text: "Smart ", style: TextStyle(color: deepBlue)),
        TextSpan(text: "Budget", style: TextStyle(color: appGreen)),
      ],
    ),
  );

  Widget _buildTopIcon(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
    ),
    child: const Column(
      children: [
        Icon(Icons.assignment_ind_rounded, size: 40, color: deepBlue),
        Text("NEW ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black38)),
      ],
    ),
  );

  Widget _buildFooter(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Already have an account? ", style: TextStyle(color: Colors.black38, fontSize: 13)),
      GestureDetector(
        onTap: () { _playClickSound(); Get.back(); },
        child: const Text(
          "Log In",
          style: TextStyle(color: appGreen, fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ),
    ],
  );

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 200, height: 200,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 80, spreadRadius: 40)]
      )
  );
}