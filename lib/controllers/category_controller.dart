import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضروري للأصوات والاهتزاز

class CategoryController extends GetxController {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ===============================
  /// جلب الفئات حسب النوع
  /// ===============================

  Stream<List<Map<String, dynamic>>> getCategories(bool isExpense) {

    String uid = _auth.currentUser!.uid;
    String type = isExpense ? "expense" : "income";

    return _db
        .collection('users')
        .doc(uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) {

      var list = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();

      /// فلترة حسب النوع داخل Flutter
      return list.where((cat) => cat["type"] == type).toList();
    });
  }

  /// ===============================
  /// إضافة فئة
  /// ===============================

  Future<void> addCategory({
    required String name,
    required int icon,
    required int color,
    required bool isExpense,
  }) async {

    try {

      String uid = _auth.currentUser!.uid;
      String type = isExpense ? "expense" : "income";

      /// منع تكرار الاسم

      QuerySnapshot exist = await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .where("name", isEqualTo: name)
          .get();

      if (exist.docs.isNotEmpty) {
        // تم استبدال warningImpact بـ vibrate لأنه المسمى الصحيح
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.click);

        Get.snackbar(
          "Duplicate",
          "Category already exists",
          backgroundColor: Colors.orange,
        );

        return;
      }

      DocumentReference docRef = _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc();

      await docRef.set({

        "category_id": docRef.id,
        "name": name,
        "icon": icon,
        "color": color,
        "type": type,

        "is_system": false, // فئة المستخدم

        "created_at": FieldValue.serverTimestamp(),

      });

      // نجاح: اهتزاز خفيف وصوت
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);

      Get.snackbar(
        "Success",
        "Category added",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _logActivity(
        title: "New Category",
        description: "Category $name created",
      );

    } catch (e) {
      // خطأ: اهتزاز قوي
      HapticFeedback.heavyImpact();

      Get.snackbar(
        "Error",
        "Failed to add category",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

    }

  }

  /// ===============================
  /// تعديل الفئة
  /// ===============================

  Future<void> updateCategory({
    required String id,
    required String name,
    required int icon,
    required int color,
  }) async {

    try {

      String uid = _auth.currentUser!.uid;

      await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(id)
          .update({

        "name": name,
        "icon": icon,
        "color": color,
        "updated_at": FieldValue.serverTimestamp(),

      });

      // تعديل: اهتزاز متوسط وصوت
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);

      Get.snackbar(
        "Updated",
        "Category updated",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
        "Error",
        "Failed to update category",
        backgroundColor: Colors.red,
      );

    }

  }

  /// ===============================
  /// حذف فئة
  /// ===============================


  Future<void> deleteCategory(String categoryId) async {

    try {

      String uid = _auth.currentUser!.uid;

      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId)
          .get();

      bool isSystem = doc["is_system"] ?? false;

      if (isSystem) {
        // منع: اهتزاز طويل وصوت
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.click);

        Get.snackbar(
          "Restricted",
          "Default categories cannot be deleted",
          backgroundColor: Colors.orange,
        );

        return;

      }

      await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId)
          .delete();

      // حذف: اهتزاز اختيار وصوت
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);

      Get.snackbar(
        "Deleted",
        "Category removed",
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
      );

    } catch (e) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
        "Error",
        "Could not delete category",
        backgroundColor: Colors.red,
      );

    }

  }

  /// ===============================
  /// تسجيل النشاط
  /// ===============================

  Future<void> _logActivity({
    required String title,
    required String description,
  }) async {

    String uid = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .add({

      "title": title,
      "description": description,
      "type": "category",
      "timestamp": FieldValue.serverTimestamp(),

    });

  }

}