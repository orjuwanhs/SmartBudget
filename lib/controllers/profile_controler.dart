import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart'; // مكتبة البصمة
import '../../models/user_model.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  RxBool isLoading = false.obs;
  RxBool isDarkMode = false.obs;
  RxBool isNotificationsEnabled = true.obs;
  RxBool isBiometricEnabled = false.obs;
  RxString profilePicUrl = "".obs;
  RxString currentLanguage = "English".obs;
  final box = GetStorage(); // Permanent storage

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.isDarkMode;
// Load the saved state from storage on app start
    isBiometricEnabled.value = box.read('biometric_enabled') ?? false;
    // Load saved notification preference, default is true
    isNotificationsEnabled.value = box.read('notifications_enabled') ?? true;

 }

  // --- جلب بيانات المستخدم من Firestore ---
  Stream<UserModel> get userDataStream {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(UserModel(fullName: "Guest", email: "", phone: "", currency: "SAR"));
    }

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final user = UserModel.fromMap(snapshot.data()!);
        // تحديث الصورة إذا كانت مخزنة في قاعدة البيانات
        // profilePicUrl.value = user.profilePic ?? ""; 
        return user;
      } else {
        return UserModel(fullName: "New User", email: "", phone: "", currency: "SAR");
      }
    });
  }

  // --- التحكم بالسمة (Dark/Light Mode) ---
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }




  void toggleNotifications(bool val) async {
    isNotificationsEnabled.value = val;
    // Save the state permanently
    await box.write('notifications_enabled', val);

    if (val) {
      // Logic to enable notifications (e.g., Firebase Messaging subscribe)
      // await FirebaseMessaging.instance.subscribeToTopic("all");

      Get.snackbar(
        "Notifications",
        "Notifications have been enabled",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        icon: Icon(Icons.notifications_active, color: Colors.green),
      );
    } else {
      // Logic to disable notifications (e.g., Firebase Messaging unsubscribe)
      // await FirebaseMessaging.instance.unsubscribeFromTopic("all");

      Get.snackbar(
        "Notifications",
        "Notifications have been disabled",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.1),
        icon: Icon(Icons.notifications_off, color: Colors.orange),
      );
    }
  }
  // --- التحقق من البصمة وتفعيلها ---
  Future<void> toggleBiometric(bool val) async {
    if (val) {
      try {
        bool canCheck = await _localAuth.canCheckBiometrics;
        bool isSupported = await _localAuth.isDeviceSupported();

        if (canCheck && isSupported) {
          // Request authentication to verify the user before enabling
          bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Please authenticate to enable biometric security',
            options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: true
            ),
          );

          if (authenticated) {
            isBiometricEnabled.value = true;
            await box.write('biometric_enabled', true); // Save as TRUE
            Get.snackbar("Security", "Biometric enabled successfully",
                backgroundColor: Colors.green.withOpacity(0.1));
          } else {
            isBiometricEnabled.value = false;
          }
        } else {
          Get.snackbar("Error", "Biometric not supported on this device");
          isBiometricEnabled.value = false;
        }
      } catch (e) {
        debugPrint("Biometric Error: $e");
        isBiometricEnabled.value = false;
      }
    } else {
      // If the user turns it OFF from settings
      isBiometricEnabled.value = false;
      await box.write('biometric_enabled', false); // Save as FALSE
      Get.snackbar("Security", "Biometric disabled",
          backgroundColor: Colors.orange.withOpacity(0.1));
    }
  }

  // --- تحديث العملة في Firestore ---
  Future<void> updateCurrency(String code) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({'currency': code});
        Get.snackbar("Currency", "Updated to $code", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update currency");
    }
  }

  // --- تحديث اللغة ---
  void updateLanguage(String langCode, String langName) {
    currentLanguage.value = langName;
    if (langCode == 'ar') {
      Get.updateLocale(const Locale('ar', 'SA'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  // --- التقاط وصيانة صورة البروفايل ---
  Future<void> pickAndUploadImage({required bool isCamera}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
          source: isCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 50 // لتقليل حجم الصورة
      );

      if (image == null) return;

      isLoading.value = true;
      final directory = await getApplicationDocumentsDirectory();
      final String savedPath = '${directory.path}/${basename(image.path)}';
      await File(image.path).copy(savedPath);

      profilePicUrl.value = savedPath;

      // ملاحظة: لرفع الصورة لـ Firebase Storage تحتاج إضافة مكتبة firebase_storage
      // هنا نقوم بحفظ المسار محلياً فقط حالياً
    } catch (e) {
      debugPrint("Error saving image: $e");
      Get.snackbar("Error", "Could not save image");
    } finally {
      isLoading.value = false;
    }
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    try {
      await _auth.signOut();
      // التوجه لصفحة تسجيل الدخول (تأكد من تسمية الـ route في الـ main)
      Get.offAllNamed('/login_screen');
    } catch (e) {
      Get.snackbar("Error", "Logout failed: $e");
    }
  }
}