/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // أضفتها فقط للـ HapticFeedback
import 'dashboard_controller.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DashboardController dashCtrl = Get.find<DashboardController>();

  var isLoading = false.obs;
  final double lowBalanceThreshold = 100.0;

  // لون البرتقالي الموحد للتطبيق
  static const Color appOrange = Color(0xFFFF6D00);

  // دالة الإضافة مع قيود المنع الصارمة (Strict Validations)
  Future<void> addTransaction({
    required String categoryId,
    required double amount,
    required String categoryName,
    required String categoryIcon,
    required String categoryColor,
    required String type,
    required String note,
    DateTime? date,
  }) async {
    try {
      isLoading.value = true;
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return;

      bool isIncome = type.toLowerCase() == 'income';
      DocumentReference userRef = _db.collection('users').doc(uid);

      // Start Transaction to ensure data integrity
      await _db.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        // 1. Fetch Financial Data
        double currentBalance = (userSnapshot.get('total_balance') ?? 0.0).toDouble();
        double monthlyLimit = (userSnapshot.get('monthlyBudget') ?? userSnapshot.get('monthly_budget') ?? 0.0).toDouble();

        // Get current totals from DashboardController
        double totalExpense = 0.0;
        if (Get.isRegistered<DashboardController>()) {
          totalExpense = Get.find<DashboardController>().totalExpense.value;
        }

        // 2. Strict Validations for Expenses (القيود الصارمة التي طلبتها)
        if (!isIncome) {
          // Validation A: Prevent Negative Balance (منع القيم السالبة)
          if (amount > currentBalance) {
            throw "Insufficient Balance. Your current balance is $currentBalance SAR.";
          }

          // Validation B: Prevent Exceeding Monthly Global Budget (منع تجاوز الميزانية)
          if (monthlyLimit > 0 && (totalExpense + amount) > monthlyLimit) {
            throw "Transaction Denied. This exceeds your total monthly budget of $monthlyLimit SAR.";
          }

          // Validation C: Check Specific Category Budget
          String currentMonth = DateTime.now().month.toString();
          QuerySnapshot budgetSnap = await _db.collection('users').doc(uid)
              .collection('budgets')
              .where('category_name', isEqualTo: categoryName)
              .where('month', isEqualTo: currentMonth)
              .limit(1).get();

          if (budgetSnap.docs.isNotEmpty) {
            var bData = budgetSnap.docs.first.data() as Map<String, dynamic>;
            double catLimit = (bData['limit_amount'] ?? 0.0).toDouble();

            // هنا يمكنك إضافة منطق حساب صرف الفئة الحالي إذا أردت منعاً أدق
            if (catLimit > 0 && amount > catLimit) {
              throw "Transaction Denied. You have reached the limit for $categoryName ($catLimit SAR).";
            }
          }
        }

        // 3. Execution (If all validations pass)
        double newBalance = isIncome ? currentBalance + amount : currentBalance - amount;
        DocumentReference transRef = userRef.collection('transactions').doc();

        transaction.set(transRef, {
          'id': transRef.id,
          'category_id': categoryId,
          'amount': amount,
          'type': type.toLowerCase(),
          'category_name': categoryName,
          'category_icon': categoryIcon,
          'category_color': categoryColor,
          'note': note,
          'balance_before': currentBalance,
          'balance_after': newBalance,
          'timestamp': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
        });

        // Update the user's main document
        transaction.update(userRef, {
          'total_balance': newBalance,
          'last_transaction_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(), // مضافة من كودك الأول
        });
      });

      // 4. Post-Transaction Updates
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().listenToTransactions();
      }

      await _handlePostTransaction(type, amount, categoryName, uid);

      Get.back(); // Close the entry sheet/page

      _showAppNotification(
          "Success",
          isIncome ? "Added +$amount to balance" : "Recorded -$amount expense",
          isError: false,
          customColor: isIncome ? Colors.green.shade700 : Colors.orange.shade800
      );

    } catch (e) {
      _showAppNotification(
          "Action Blocked",
          e.toString().replaceAll("Exception: ", ""),
          isError: true
      );
    } finally {
      isLoading.value = false;
    }
  }

  // دالة التحقق والتنبيه (التي تُستدعى قبل الحفظ لتعطي خيار الاستمرار)
  void validateAndConfirm({
    required double amount,
    required String type,
    required String categoryName,
    required Function onConfirmed,
  }) {
    double currentBalance = dashCtrl.totalIncome.value - dashCtrl.totalExpense.value;
    double monthlyLimit = dashCtrl.monthlyBudget.value;
    double totalSpent = dashCtrl.totalExpense.value;

    if (type.toLowerCase() == 'expense' && amount > currentBalance) {
      _showAppNotification(
        "Insufficient Balance",
        "You only have $currentBalance SAR available.",
        isError: true,
      );
      return;
    }

    if (type.toLowerCase() == 'expense' && monthlyLimit > 0 && (totalSpent + amount) > monthlyLimit) {
      Get.defaultDialog(
        title: "Budget Exceeded",
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
        backgroundColor: Colors.white,
        radius: 20,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 50),
            const SizedBox(height: 15),
            Text(
              "This $categoryName expense will push you over your monthly limit of $monthlyLimit SAR.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text("Do you want to proceed anyway?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        cancel: TextButton(
          onPressed: () => Get.back(),
          child: Text("CANCEL", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ),
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Get.back();
            onConfirmed();
          },
          child: const Text("PROCEED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    } else {
      onConfirmed();
    }
  }

  Future<void> _handlePostTransaction(String type, double amount, String categoryName, String uid) async {
    try {
      DocumentSnapshot userSnap = await _db.collection('users').doc(uid).get();
      double currentBalance = (userSnap.get('total_balance') ?? 0.0).toDouble();
      double monthlyLimit = (userSnap.get('monthlyBudget') ?? 0.0).toDouble();

      dashCtrl.logActivity(
        title: type.toLowerCase() == 'income' ? "Deposit Received 💰" : "Payment Made 🧾",
        description: "$categoryName: $amount",
        type: 'transaction',
        amount: amount,
      );

      if (type.toLowerCase() == 'expense') {
        await dashCtrl.checkBudgetUpdated(amount, monthlyLimit);
        _checkSpecificCategoryBudget(categoryName, amount, uid);
      }

      if (currentBalance <= 0) {
        _playAlertSound();
        await NotificationService().lowBalance(currentBalance);
      } else if (currentBalance < 500 && type.toLowerCase() == 'expense') {
        _playAlertSound();
        await NotificationService().lowBalance(currentBalance);
      }
    } catch (e) {
      debugPrint("Side Effects Error: $e");
    }
  }

  Future<void> _checkSpecificCategoryBudget(String categoryName, double amount, String uid) async {
    try {
      String month = DateTime.now().month.toString();
      var budgetSnap = await _db.collection('users').doc(uid).collection('budgets')
          .where('category_name', isEqualTo: categoryName)
          .where('month', isEqualTo: month)
          .get();

      if (budgetSnap.docs.isNotEmpty) {
        var bData = budgetSnap.docs.first.data();
        double limit = (bData['limit_amount'] ?? 0.0).toDouble();
        dashCtrl.checkAndAlertCategory(categoryName, amount, limit);
      }
    } catch (e) {
      debugPrint("Category Budget Check Error: $e");
    }
  }

  void _showAppNotification(String title, String message, {required bool isError, Color? customColor}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: customColor ?? (isError ? appOrange : const Color(0xFF103667)),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(15),
      icon: Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white),
    );
  }

  void _playAlertSound() {
    HapticFeedback.vibrate();
  }
}

*/