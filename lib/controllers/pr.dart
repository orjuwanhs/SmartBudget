import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  RxBool isLoading = false.obs;
  RxBool isDarkMode = false.obs;
  RxBool isNotificationsEnabled = true.obs;
  RxBool isBiometricEnabled = false.obs;
  RxString profilePicUrl = "".obs;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.isDarkMode;
    _loadInitialData();
  }

  // إصلاح خطأ الصورة f0c2ca عبر تمرير بيانات افتراضية للموديل
  Stream<UserModel> get userDataStream {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // تمرير قيم فارغة لتجنب خطأ "required parameter"
        return UserModel(email: '', fullName: '', phone: '');
      }
      final data = snapshot.data() as Map<String, dynamic>;
      profilePicUrl.value = data['profile_image'] ?? "";
      return UserModel.fromMap(data);
    });
  }

  Future<void> _loadInitialData() async {
    if (uid == null) return;
    try {
      var doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        profilePicUrl.value = doc.data()?['profile_image'] ?? "";
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleNotifications(bool val) => isNotificationsEnabled.value = val;
  void toggleBiometric(bool val) => isBiometricEnabled.value = val;

  Future<void> updateCurrency(String code) async {
    try {
      await _firestore.collection('users').doc(uid).update({'currency': code});
    } catch (e) {
      _showSnackBar("خطأ", "فشل تحديث العملة");
    }
  }

  Future<void> pickAndUploadImage({required bool isCamera}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
      );

      if (image == null) return;

      isLoading.value = true;
      File file = File(image.path);

      Reference ref = _storage.ref().child('profile_images').child('$uid.jpg');
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'profile_image': downloadUrl,
      });

      profilePicUrl.value = downloadUrl;
      _showSnackBar("نجاح", "تم تحديث الصورة بنجاح", isError: false);
    } catch (e) {
      _showSnackBar("خطأ", "فشل الرفع: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  void _showSnackBar(String title, String message, {bool isError = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title, message,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    });
  }
}