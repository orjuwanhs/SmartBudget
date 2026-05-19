import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_controller.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // استخدام دالة آمنة لإيجاد الكنترولر لتجنب الأخطاء عند أول تشغيل
  DashboardController get dashCtrl => Get.find<DashboardController>();

  var isLoading = false.obs;
  final double lowBalanceThreshold = 100.0;

  static const Color appOrange = Color(0xFFFF6D00);

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

      bool isIncome = type.toLowerCase().contains('inc'); // تحسين التحقق ليشمل "Income" أو "income"
      DocumentReference userRef = _db.collection('users').doc(uid);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        // تأمين جلب البيانات مع قيم افتراضية للمستخدم الجديد
        double currentBalance = 0.0;
        try { currentBalance = (userSnapshot.get('total_balance') ?? 0.0).toDouble(); } catch(e) { currentBalance = 0.0; }

        double monthlyLimit = 0.0;
        try { monthlyLimit = (userSnapshot.get('monthlyBudget') ?? userSnapshot.get('monthly_budget') ?? 0.0).toDouble(); } catch(e) { monthlyLimit = 0.0; }

        double totalExpense = dashCtrl.totalExpense.value;

        // 2. Strict Validations (تطبق فقط على المصاريف Expense)
        if (!isIncome) {
          // منع الرصيد السالب
          if (amount > currentBalance) {
            throw "Insufficient Balance. Your current balance is $currentBalance SAR.";
          }

          // منع تجاوز الميزانية الكلية (فقط إذا كانت الميزانية محددة > 0)
          if (monthlyLimit > 0 && (totalExpense + amount) > monthlyLimit) {
            throw "Transaction Denied. This exceeds your total monthly budget of $monthlyLimit SAR.";
          }

          // التحقق من ميزانية الفئة المحددة
          String currentMonth = DateTime.now().month.toString();
          var budgetDocs = await _db.collection('users').doc(uid)
              .collection('budgets')
              .where('category_name', isEqualTo: categoryName)
              .where('month', isEqualTo: currentMonth)
              .limit(1).get();

          if (budgetDocs.docs.isNotEmpty) {
            var bData = budgetDocs.docs.first.data();
            double catLimit = (bData['limit_amount'] ?? 0.0).toDouble();
            if (catLimit > 0 && amount > catLimit) {
              throw "Transaction Denied. This exceeds $categoryName limit ($catLimit SAR).";
            }
          }
        }

        // 3. Execution
        double newBalance = isIncome ? currentBalance + amount : currentBalance - amount;
        DocumentReference transRef = userRef.collection('transactions').doc();

        transaction.set(transRef, {
          'id': transRef.id,
          'category_id': categoryId,
          'amount': amount,
          'type': isIncome ? 'income' : 'expense',
          'category_name': categoryName,
          'category_icon': categoryIcon,
          'category_color': categoryColor,
          'note': note,
          'balance_before': currentBalance,
          'balance_after': newBalance,
          'timestamp': date != null ? Timestamp.fromDate(date) : FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'total_balance': newBalance,
          'last_transaction_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      // 4. Post-Transaction Updates
      dashCtrl.listenToTransactions();
      await _handlePostTransaction(type, amount, categoryName, uid);

      Get.back();

      //if (Get.isOverlaysOpen) Get.back(); // إغلاق الشاشة فقط إذا كانت مفتوحة
// ثانياً: إظهار رسالة النجاح (ستظهر فوق صفحة الداشبورد الآن)
      _showAppNotification(
          "Success",
          isIncome ? "Added +$amount to balance" : "Recorded -$amount expense",
          isError: false,
          customColor: isIncome ? Colors.green.shade700 : Colors.orange.shade800
      );

    } catch (e) {
      // في حالة الخطأ لا نعود للخلف، نترك المستخدم يصحح الخطأ
      _showAppNotification(
          "Action Blocked",
          e.toString().replaceAll("Exception: ", ""),
          isError: true
      );
    } finally {
      isLoading.value = false;
    }

  }

  void validateAndConfirm({
    required double amount,
    required String type,
    required String categoryName,
    required Function onConfirmed,
  }) {
    bool isIncome = type.toLowerCase().contains('inc');
    double currentBalance = dashCtrl.totalIncome.value - dashCtrl.totalExpense.value;
    double monthlyLimit = dashCtrl.monthlyBudget.value;
    double totalSpent = dashCtrl.totalExpense.value;

    // الدخل لا يحتاج تأكيد أو فحص ميزانية
    if (isIncome) {
      onConfirmed();
      return;
    }

    if (amount > currentBalance) {
      _showAppNotification("Insufficient Balance", "You only have $currentBalance SAR.", isError: true);
      return;
    }

    if (monthlyLimit > 0 && (totalSpent + amount) > monthlyLimit) {
      Get.defaultDialog(
        title: "Budget Exceeded",
        titleStyle: const TextStyle(fontWeight: FontWeight.w900),
        content: Text("This will push you over your $monthlyLimit SAR limit. Proceed?"),
        textConfirm: "PROCEED",
        textCancel: "CANCEL",
        confirmTextColor: Colors.white,
        buttonColor: Colors.orangeAccent,
        onConfirm: () {
          Get.back();
          onConfirmed();
        },
      );
    } else {
      onConfirmed();
    }
  }

  Future<void> _handlePostTransaction(String type, double amount, String categoryName, String uid) async {
    try {
      bool isExpense = type.toLowerCase().contains('exp');
      DocumentSnapshot userSnap = await _db.collection('users').doc(uid).get();
      double currentBalance = 0.0;
      try { currentBalance = (userSnap.get('total_balance') ?? 0.0).toDouble(); } catch(e){}

      dashCtrl.logActivity(
        title: isExpense ? "Payment Made 🧾" : "Deposit Received 💰",
        description: "$categoryName: $amount",
        type: 'transaction',
        amount: amount,
      );

      if (isExpense) {
        // تحديث وفحص الميزانية الذكي (85%، 90%، 100%)
        await dashCtrl.checkBudgetUpdated(dashCtrl.totalExpense.value, dashCtrl.monthlyBudget.value);
        _checkSpecificCategoryBudget(categoryName, amount, uid);
      }

      // تنبيهات الرصيد المنخفض
      if (currentBalance <= 0) {
        _playAlertSound();
        await NotificationService().lowBalance(currentBalance);
      } else if (currentBalance < 500 && isExpense) {
        _playAlertSound();
        await NotificationService().lowBalance(currentBalance);
      }
    } catch (e) {
      debugPrint("Post-Transaction Error: $e");
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
        // استدعاء فحص الفئة من الداش بورد
        dashCtrl.checkAndAlertCategory(categoryName, dashCtrl.totalExpense.value, limit);
      }
    } catch (e) {
      debugPrint("Category Budget Check Error: $e");
    }
  }

  void _showAppNotification(String title, String message, {required bool isError, Color? customColor}) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title, message,
      backgroundColor: customColor ?? (isError ? appOrange : const Color(0xFF103667)),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      icon: Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white),
    );
  }

  void _playAlertSound() {
    HapticFeedback.vibrate();
  }
}