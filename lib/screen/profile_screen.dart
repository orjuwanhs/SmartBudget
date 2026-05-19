import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controler.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController profileController = Get.put(ProfileController());

  ProfileScreen({super.key});

  static Color getBgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  static Color getTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
  static Color getCardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("SETTINGS", style: TextStyle(color: getTextColor(context), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          Obx(() => IconButton(
            icon: Icon(profileController.isDarkMode.value ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => profileController.toggleTheme(),
            color: getTextColor(context),
          )),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -80, right: -40, child: _buildBlurBlob(const Color(0xFF2DD4BF).withOpacity(0.04))),
          SafeArea(
            child: StreamBuilder<UserModel>(
              stream: profileController.userDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8), strokeWidth: 2));
                }
                final user = snapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(user, profileController, context),
                      const SizedBox(height: 25),

                      _buildSectionLabel("PREFERENCES", context),
                      _buildSettingsSection(profileController, user, context),

                      const SizedBox(height: 20),
                      _buildSectionLabel("SUPPORT & LEGAL", context),
                      _buildSupportSection(context),

                      const SizedBox(height: 25),
                      Text("v 1.0.2", style: TextStyle(color: getTextColor(context).withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- قسم الإعدادات المحدث ---
  Widget _buildSettingsSection(ProfileController controller, UserModel? user, BuildContext context) {
    return _buildCleanContainer(
      context: context,
      child: Column(
        children: [
          // خيار العملة
          _buildProfileTile(context, Icons.payments_rounded, "Currency", user?.currency ?? "SAR", Colors.orangeAccent, () => _showCurrencyPicker(controller, context)),
          _buildDivider(),

          // خيار اللغة (الجديد)
          _buildProfileTile(context, Icons.translate_rounded, "Language", "English", Colors.purpleAccent, () => _showLanguagePicker(controller, context)),
          _buildDivider(),

          // خيار الإشعارات (On/Off)
          Obx(() => _buildSwitchTile(
              context,
              Icons.notifications_active_rounded,
              "Push Notifications",
              Colors.greenAccent.shade700,
              controller.isNotificationsEnabled.value,
                  (val) => controller.toggleNotifications(val)
          )),
          _buildDivider(),

          // خيار البصمة (On/Off)
          Obx(() => _buildSwitchTile(
              context,
              Icons.fingerprint_rounded,
              "Biometric Security",
              Colors.blueAccent,
              controller.isBiometricEnabled.value,
                  (val) => controller.toggleBiometric(val)
          )),
        ],
      ),
    );
  }

  // --- شاشة اختيار اللغة ---
  void _showLanguagePicker(ProfileController controller, BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: getCardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            Text("Select Language", style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _languageItem("English", "en", context),
            _languageItem("العربية", "ar", context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _languageItem(String name, String code, BuildContext context) {
    return ListTile(
      title: Text(name, style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.w600)),
      trailing: code == "en" ? const Icon(Icons.check_circle, color: Colors.blue, size: 20) : null, // مثال بسيط للتحديد
      onTap: () {
        // هنا تضع منطق تغيير اللغة الخاص بك
        Get.back();
        Get.snackbar("Language", "Language changed to $name", snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  // --- بقية الـ Widgets المساعدة ---

  Widget _buildProfileHeader(UserModel? user, ProfileController controller, BuildContext context) {
    return Column(
      children: [
        Obx(() {
          ImageProvider? profileImage;
          if (controller.profilePicUrl.value.isNotEmpty) {
            profileImage = FileImage(File(controller.profilePicUrl.value));
          } else {
            profileImage = null;
          }

          return GestureDetector(
            onTap: () => _showImageSourceDialog(controller, context),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade100, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: getCardColor(context),
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Icon(Icons.person, size: 60, color: getTextColor(context).withOpacity(0.2))
                        : null,
                  ),
                ),
                if (controller.isLoading.value)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(user?.fullName ?? "User Name",
            style: TextStyle(color: getTextColor(context), fontSize: 18, fontWeight: FontWeight.w900)),
        Text(user?.email ?? "email@example.com",
            style: TextStyle(color: getTextColor(context).withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSwitchTile(BuildContext context, IconData icon, String title, Color color, bool value, Function(bool) onChanged) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(color: getTextColor(context), fontSize: 13, fontWeight: FontWeight.w800)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: color,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildCleanContainer(
      context: context,
      child: Column(
        children: [
          _buildProfileTile(context, Icons.help_center_rounded, "Help Center", "", Colors.purpleAccent, () {}),
          _buildDivider(),
          _buildProfileTile(context, Icons.policy_rounded, "Privacy Policy", "", Colors.tealAccent.shade700, () {}),
          _buildDivider(),
       ],
      ),
    );
  }

  void _showCurrencyPicker(ProfileController controller, BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: getCardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            Text("Select Currency", style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _currencyItem("SAR", controller, context),
            _currencyItem("USD", controller, context),
            _currencyItem("EUR", controller, context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _currencyItem(String code, ProfileController controller, BuildContext context) {
    return ListTile(
      title: Text(code, style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold)),
      onTap: () { controller.updateCurrency(code); Get.back(); },
    );
  }

  void _showImageSourceDialog(ProfileController controller, BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: getCardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Update Profile Picture", style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
              title: Text("Gallery", style: TextStyle(color: getTextColor(context))),
              onTap: () { Get.back(); controller.pickAndUploadImage(isCamera: false); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.orange),
              title: Text("Camera", style: TextStyle(color: getTextColor(context))),
              onTap: () { Get.back(); controller.pickAndUploadImage(isCamera: true); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String trailing, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(color: getTextColor(context), fontSize: 13, fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty) Text(trailing, style: TextStyle(color: getTextColor(context).withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded, color: getTextColor(context).withOpacity(0.1), size: 12),
        ],
      ),
    );
  }

  Widget _buildCleanContainer({required Widget child, required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(color: getCardColor(context), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: child,
    );
  }

  Widget _buildSectionLabel(String text, BuildContext context) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 10, bottom: 8), child: Text(text, style: TextStyle(color: getTextColor(context).withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold))));
  Widget _buildDivider() => Divider(color: Colors.grey.withOpacity(0.1), height: 1, indent: 55);
  Widget _buildBlurBlob(Color color) => Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)]));
}