import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// تأكد من استيراد خدمة الإشعارات إذا كانت في ملف منفصل
// import '../services/notification_service.dart';

class GoalController extends GetxController {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ================================
  /// Stream Goals
  /// ================================
  Stream<List<Map<String, dynamic>>> get goalsStream {

    String uid = _auth.currentUser!.uid;

    return _db
        .collection('users')
        .doc(uid)
        .collection('savings_goals')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            ...doc.data(),
          };
        }).toList());
  }

  /// للحفاظ على التوافق مع الصفحات القديمة
  Stream<List<Map<String, dynamic>>> get savingsGoalsStream => goalsStream;

  /// ================================
  /// Create Goal
  /// ================================
  Future<void> createGoal({
    required String name,
    required double target,
    required String icon,
    required String color,
  }) async {

    try {

      String uid = _auth.currentUser!.uid;

      DocumentReference goalRef = _db
          .collection('users')
          .doc(uid)
          .collection('savings_goals')
          .doc();

      await goalRef.set({

        "goal_id": goalRef.id,
        "name": name,
        "target": target,
        "saved": 0.0,
        "icon": icon,
        "color": color,
        "completed": false,
        "created_at": FieldValue.serverTimestamp(),

      });

      await _logActivity(
          title: "New Savings Goal",
          description: "Goal '$name' created with target $target"
      );

      Get.snackbar(
        "Goal Created",
        "Savings goal added successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {

      Get.snackbar(
        "Error",
        "Could not create goal",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

    }

  }

  /// ================================
  /// Add Money To Goal
  /// ================================
  var isLoading = false.obs;

  Future<void> addMoneyToGoal(String goalId, double amount) async {
    if (isLoading.value) return; // منع التنفيذ إذا كانت هناك عملية جارية

    try {
      isLoading.value = true;
      String uid = _auth.currentUser!.uid;
      DocumentReference userRef = _db.collection('users').doc(uid);
      DocumentReference goalRef = userRef.collection('savings_goals').doc(goalId);

      await _db.runTransaction((transaction) async {
        // ... نفس منطق الترانزاكشن الأصلي الخاص بك بدون حذف سطر ...
        DocumentSnapshot goalSnap = await transaction.get(goalRef);
        DocumentSnapshot userSnap = await transaction.get(userRef);
        Map<String, dynamic> goalData = goalSnap.data() as Map<String, dynamic>;
        Map<String, dynamic> userData = userSnap.data() as Map<String, dynamic>? ?? {};

        double saved = (goalData['saved'] ?? 0).toDouble();
        double target = (goalData['target'] ?? 0).toDouble();
        double balance = (userData['total_balance'] ?? 0).toDouble();

        if (amount > balance) throw Exception("Insufficient balance");

        double newSaved = saved + amount;
        if (newSaved > target) {
          amount = target - saved;
          newSaved = target;
        }

        bool completed = newSaved >= target;

        transaction.update(goalRef, {"saved": newSaved, "completed": completed});
        transaction.update(userRef, {"total_balance": FieldValue.increment(-amount)});

        DocumentReference historyRef = goalRef.collection("history").doc();
        transaction.set(historyRef, {
          "amountAdded": amount,
          "status": completed ? "Goal Reached" : "Saved",
          "date": FieldValue.serverTimestamp()
        });
      });

      await _logActivity(title: "Savings Deposit", description: "Added $amount to goal");
      await _checkGoalCompletion(goalId);

    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false; // إعادة الحالة لوضعها الطبيعي
    }
  }

  /// ================================
  /// Goal Completion Notification (Updated with Feedback)
  /// ================================
  Future<void> _checkGoalCompletion(String goalId) async {

    String uid = _auth.currentUser!.uid;

    DocumentSnapshot goalSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('savings_goals')
        .doc(goalId)
        .get();

    if (!goalSnap.exists) return;

    Map<String, dynamic> goal =
    goalSnap.data() as Map<String, dynamic>;

    if (goal['completed'] == true) {

      // 1. تشغيل الاهتزاز عند الاكتمال
      HapticFeedback.heavyImpact();

      // 2. إضافة إشعار لقاعدة البيانات
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        "title": "Goal Completed 🎉",
        "body": "Congratulations! You reached '${goal['name']}'",
        "type": "goal",
        "isRead": false,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 3. إظهار رسالة نجاح فورية (Snackbar)
      Get.snackbar(
        "Target Achieved! 🏆",
        "Congratulations on reaching your goal: ${goal['name']}",
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        icon: const Icon(Icons.celebration_rounded),
        duration: const Duration(seconds: 4),
      );

      // 4. (اختياري) استدعاء خدمة الإشعارات الخارجية إذا كانت مفعله لديك
      // NotificationService().showNotification(
      //   title: "Goal Reached!",
      //   body: "You have successfully saved for ${goal['name']}",
      // );
    }

  }

  /// ================================
  /// Delete Goal
  /// ================================
  Future<void> deleteGoal(String goalId) async {

    try {

      String uid = _auth.currentUser!.uid;

      await _db
          .collection('users')
          .doc(uid)
          .collection('savings_goals')
          .doc(goalId)
          .delete();

      await _logActivity(
          title: "Goal Deleted",
          description: "A savings goal was removed"
      );

      Get.snackbar(
        "Goal Removed",
        "Savings goal deleted",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

    } catch (e) {

      Get.snackbar(
        "Error",
        "Could not delete goal",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

    }

  }

  /// ================================
  /// Activity Log
  /// ================================
  Future<void> _logActivity({
    required String title,
    required String description,
  }) async {

    String uid = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .add({

      "title": title,
      "description": description,
      "type": "goal",
      "timestamp": FieldValue.serverTimestamp(),

    });

  }

}