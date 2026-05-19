import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../thems/app_theme.dart';
import '../screen/dashboard_screen.dart';

import 'package:get_storage/get_storage.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  // --- Variables ---
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isCodeExpired = false.obs;
  var timeLeft = 600.obs;
  var rememberMe = true.obs;
  String _verificationId = "";
  Timer? _timer;

  // =========================================================
  // 1️⃣ BIOMETRIC LOGIN (البصمة مع التشفير)
  // =========================================================

  // تم تغيير اسم الدالة لتتوافق مع استدعائك وتصحيح الخطأ
  Future<void> _performBiometricAuth() async {
    try {
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Login to your account',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (didAuthenticate) {
        String? email = await _storage.read(key: 'email');
        String? pass = await _storage.read(key: 'password');

        if (email != null && pass != null) {
          isLoading.value = true;
          await _auth.signInWithEmailAndPassword(email: email, password: pass);

          // الحل النهائي للخطأ الأحمر: الانتظار حتى استقرار الفريم
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/home');
          });
        } else {
          AppStyles.showErrorSnackbar("Error", "No saved credentials found. Please login manually first.");
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Biometric login failed");
    } finally {
      isLoading.value = false;
    }
  }


  final box = GetStorage();

// =========================================================
  // 1️⃣ BIOMETRIC LOGIN (The Correct Integrated Way)
  // =========================================================

  Future<void> loginWithBiometric() async {
    // 1. التحقق من إعدادات المستخدم (هل سمح بالبصمة؟)
    bool isEnabled = box.read('biometric_enabled') ?? false;

    if (!isEnabled) {
      Get.snackbar(
        "Security Notice",
        "Please enable biometric login from app settings first.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        icon: const Icon(Icons.lock_person, color: Colors.white),
      );
      return;
    }

    try {
      // 2. إظهار نافذة البصمة الخاصة بالنظام
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        isLoading.value = true;

        // 3. جلب البيانات المشفرة المخزنة مسبقاً
        String? email = await _storage.read(key: 'email');
        String? pass = await _storage.read(key: 'password');

        if (email != null && pass != null) {
          // 4. تسجيل الدخول الفعلي في Firebase
          await _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: pass.trim()
          );

          // 5. الانتقال للصفحة الرئيسية مع ضمان استقرار الـ UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/home');
          });
        } else {
          AppStyles.showErrorSnackbar("Error", "No saved credentials found. Please login with password first.");
        }
      }
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
      Get.snackbar("Error", "Authentication failed. Use password.");
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // 2️⃣ LOGIN (Improved with Security Storage)
  // =========================================================

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      AppStyles.showErrorSnackbar("Missing Data", "Please enter email and password");
      return;
    }

    try {
      isLoading.value = true;
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // حفظ البيانات مشفرة فور نجاح الدخول لتكون متاحة للبصمة مستقبلاً
      await _storage.write(key: 'email', value: email.trim());
      await _storage.write(key: 'password', value: password.trim());

      String uid = userCredential.user!.uid;
      await _initializeUserData(uid, email.trim());

      AppStyles.showSuccessSnackbar("Success!", "Logged in successfully");

      // التوجه للهوم
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
      });

    } on FirebaseAuthException catch (e) {
      AppStyles.showErrorSnackbar("Login Failed", e.message ?? "Check credentials");
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // 3️⃣ INITIALIZE USER DATABASE
  // =========================================================

  Future<void> _initializeUserData(String uid, String email) async {
    DocumentReference userRef = _db.collection("users").doc(uid);
    DocumentSnapshot userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        "email": email,
        "created_at": FieldValue.serverTimestamp(),
      });
    }

    DocumentReference profileRef = userRef.collection("profile").doc("data");
    DocumentSnapshot profileDoc = await profileRef.get();
    if (!profileDoc.exists) {
      await profileRef.set({
        "full_name": "",
        "phone": "",
        "currency": "SAR",
        "profile_pic": null,
        "total_balance": 0,
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      });
    }

    String monthId = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    DocumentReference statsRef = userRef.collection("stats").doc(monthId);
    DocumentSnapshot statsDoc = await statsRef.get();
    if (!statsDoc.exists) {
      await statsRef.set({
        "total_income": 0,
        "total_expense": 0,
        "balance": 0,
        "updated_at": FieldValue.serverTimestamp(),
      });
    }
  }

  // =========================================================
  // 4️⃣ OTP & PHONE VERIFICATION
  // =========================================================

  void startTimer() {
    isCodeExpired.value = false;
    timeLeft.value = 600;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        isCodeExpired.value = true;
        _timer?.cancel();
      }
    });
  }

  Future<void> sendOtp(String phoneNumber) async {
    try {
      isLoading.value = true;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          AppStyles.showErrorSnackbar("Error", e.message ?? "Failed to send code");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          isLoading.value = false;
          startTimer();
          Get.toNamed('/reset-success', arguments: phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (isCodeExpired.value) {
      AppStyles.showErrorSnackbar("Expired", "Code expired. Request new one.");
      return false;
    }
    try {
      isLoading.value = true;
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _timer?.cancel();
      return true;
    } catch (e) {
      AppStyles.showErrorSnackbar("Error", "Invalid Code");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}