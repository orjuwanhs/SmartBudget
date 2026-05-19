import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class BudgetController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color appOrange = Color(0xFFFF6D00);



  void _showWarningSnackbar(String title, String message, {bool isCritical = false}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title, message,
        backgroundColor: isCritical ? Colors.redAccent : appOrange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: Icon(isCritical ? Icons.report_problem : Icons.notifications_active, color: Colors.white),
        duration: Duration(seconds: isCritical ? 5 : 3),
        margin: const EdgeInsets.all(15),
        borderRadius: 15,
      );
    }
  }

  /// =============================
  /// BUDGET MANAGEMENT FUNCTIONS
  /// =============================

  Future<void> updateMainMonthlyBudget(double amount) async {
    try {
      String uid = _auth.currentUser!.uid;
      String monthStr = DateTime.now().month.toString();
      String yearStr = DateTime.now().year.toString();
      String totalDocId = "total_$yearStr-$monthStr";

      await _db.collection('users').doc(uid).collection('budgets').doc(totalDocId).set({
        "category_id": "total_all",
        "category_name": "Main Budget",
        "limit_amount": amount,
        "month": monthStr,
        "year": int.parse(yearStr),
        "is_total": true,
        "updated_at": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSuccessNotification("Success", "Main budget limit set to $amount SAR");
    } catch (e) {
      Get.snackbar("Error", "Failed to update main budget");
    }
  }

  Stream<List<Map<String, dynamic>>> get budgetsStream {
    String uid = _auth.currentUser!.uid;
    String month = DateTime.now().month.toString();

    return _db.collection('users').doc(uid).collection('budgets')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList());
  }

  Future<void> createBudget({
    required String categoryId,
    required String categoryName,
    required double limit,
    String budgetType = 'Monthly',
  }) async {
    try {
      String uid = _auth.currentUser!.uid;
      String monthStr = DateTime.now().month.toString();
      String yearStr = DateTime.now().year.toString();
      String totalDocId = "total_$yearStr-$monthStr";

      DocumentSnapshot mainDoc = await _db.collection('users').doc(uid).collection('budgets').doc(totalDocId).get();
      double mainLimit = (mainDoc.exists) ? (mainDoc['limit_amount'] ?? 0.0).toDouble() : 0.0;

      QuerySnapshot existing = await _db.collection('users').doc(uid).collection('budgets')
          .where('month', isEqualTo: monthStr)
          .where('is_total', isEqualTo: false).get();

      double totalAllocated = existing.docs.fold(0, (sum, doc) => sum + (doc['limit_amount'] ?? 0.0).toDouble());

      if (totalAllocated + limit > mainLimit && mainLimit > 0) {
        _showWarningSnackbar("Roof Limit Reached", "Category budgets cannot exceed Main Budget ($mainLimit SAR)", isCritical: true);
        return;
      }

      // حساب تاريخ الانتهاء بناءً على الفلتر المختار
      DateTime now = DateTime.now();
      DateTime expiryDate;
      if (budgetType == 'Weekly') {
        expiryDate = now.add(const Duration(days: 7));
      } else if (budgetType == 'Yearly') {
        expiryDate = DateTime(now.year + 1, now.month, now.day);
      } else {
        expiryDate = DateTime(now.year, now.month + 1, now.day);
      }

      await _db.collection('users').doc(uid).collection('budgets').add({
        "category_id": categoryId,
        "category_name": categoryName,
        "limit_amount": limit,
        "spent_amount": 0.0,
        "budget_type": budgetType, // حفظ نوع الميزانية
        "expiry_date": Timestamp.fromDate(expiryDate), // حفظ تاريخ الانتهاء
        "month": monthStr,
        "year": int.parse(yearStr),
        "is_total": false,
        "created_at": FieldValue.serverTimestamp()
      });

      _showSuccessNotification("Saved", "Budget for $categoryName created ($budgetType)");
    } catch (e) {
      Get.snackbar("Error", "Failed to save budget");
    }
  }

  Stream<double> getSpentForCategory(String categoryId, double limit, String categoryName) {
    String uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('transactions')
        .snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String type = (data['type'] ?? "").toString().toLowerCase();
        bool isSameCategory = (data['category_id'] == categoryId) || (data['category_name'] == categoryName);

        if (type == 'expense' && isSameCategory) {
          total += double.tryParse((data['amount'] ?? 0.0).toString()) ?? 0.0;
        }
      }

      return total;
    });
  }

  void _showSuccessNotification(String title, String message) {
    Get.snackbar(title, message, backgroundColor: const Color(0xFF103667), colorText: Colors.white, snackPosition: SnackPosition.TOP);
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      String uid = _auth.currentUser!.uid;
      await _db.collection('users').doc(uid).collection('budgets').doc(budgetId).delete();
    } catch (e) { debugPrint(e.toString()); }
  }
}