import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'goal_controller.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<StreamSubscription> _subscriptions = [];
  final Set<String> _sessionAlerts = {};

  /// =============================
  /// Navigation & UI States
  /// =============================
  PageController pageController = PageController();
  RxInt currentIndex = 0.obs;
  RxBool isSoundEnabled = true.obs;

  void changePage(int index) {
    currentIndex.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// =============================
  /// Notifications Stream
  /// =============================
  Stream<int> get unreadNotificationsCountStream {
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// =============================
  /// Budget & Financial Stats
  /// =============================
  RxDouble monthlyBudget = 0.0.obs;
  RxDouble totalIncome = 0.0.obs;
  RxDouble totalExpense = 0.0.obs;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();

    if (uid != null) {
      _startInitialTasks();
      listenToTransactions(); // <--- تم التفعيل هنا لضمان ظهور البيانات فوراً
    } else {
      debugPrint("DashboardController: No user detected, waiting for login...");
    }
  }

  void _startInitialTasks() {
    loadBudget();
    createDefaultCategories();
    listenToFinancialData();
  }


  /// =============================
  /// Data Streams
  /// =============================
  Stream<UserModel> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _firestore.collection("users").doc(uid).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Stream<double> get totalIncomeStream {
    if (uid == null) return Stream.value(0.0);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      return snapshot.docs.fold(0.0, (sum, doc) {
        var data = doc.data();
        String type = (data["type"] ?? "").toString().toLowerCase();

        if (type == "income") {
          double value = double.tryParse((data["amount"] ?? data["income_amount"] ?? 0.0).toString()) ?? 0.0;
          return sum + value;
        }
        return sum;
      });
    });
  }

  Stream<double> get totalExpenseStream {
    if (uid == null) return Stream.value(0.0);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      return snapshot.docs.fold(0.0, (sum, doc) {
        var data = doc.data();
        String type = (data["type"] ?? "").toString().toLowerCase();

        if (type == "expense") {
          double value = double.tryParse((data["amount"] ?? data["expense_amount"] ?? 0.0).toString()) ?? 0.0;
          return sum + value;
        }
        return sum;
      });
    });
  }

  Stream<List<Map<String, dynamic>>> get recentTransactionsStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .orderBy("timestamp", descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();

        String rawType = (data['type'] ?? "").toString().toLowerCase();
        String formattedType = rawType.contains('inc') ? 'Income' : 'Expense';

        return {
          "id": doc.id,
          ...data,
          "type": formattedType,
          "categoryName": data['category_name'] ?? data['categoryName'] ?? 'General',
          "categoryIcon": data['category_icon'] ?? data['categoryIcon'],
          "categoryColor": data['category_color'] ?? data['categoryColor'],
          "amount": double.tryParse((data["amount"] ?? data["income_amount"] ?? data["expense_amount"] ?? 0.0).toString()) ?? 0.0,
        };
      }).toList();
    });
  }

  Future<void> updateTransaction(String docId, Map<String, dynamic> newData) async {
    if (uid == null) return;
    try {
      if (newData.containsKey('type')) {
        String rawType = newData['type'].toString().toLowerCase();
        newData['type'] = rawType.contains('inc') ? 'Income' : 'Expense';
      }
      await _firestore.collection("users").doc(uid).collection("transactions").doc(docId).update(newData);
      HapticFeedback.mediumImpact();
      Get.snackbar("Updated", "Transaction updated successfully", snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
      Future.delayed(const Duration(seconds: 1), () => Get.back());
    } catch (e) {
      Get.snackbar("Update Failed", "Error: ${e.toString()}", snackPosition: SnackPosition.TOP, backgroundColor: Colors.redAccent);
    }
  }

  Future<void> deleteTransaction(String docId) async {
    if (uid == null) return;
    try {
      await _firestore.collection("users").doc(uid).collection("transactions").doc(docId).delete();
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: $e");
    }
  }

  void _confirmDelete(String? docId) {
    if (docId == null) return;
    Get.defaultDialog(
      title: "Confirm Delete",
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to delete this transaction permanently?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      radius: 15,
      onConfirm: () async {
        Get.back();
        await deleteTransaction(docId);
      },
    );
  }

  Future<void> exportFinancialReport() async {
    if (uid == null) return;
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("transactions").orderBy("timestamp", descending: true).limit(50).get();
      if (snapshot.docs.isEmpty) { Get.snackbar("Export", "No data available"); return; }
      String report = "📊 Financial Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n--------------------------------\n";
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String type = data['type'] == 'Income' ? "➕" : "➖";
        report += "$type ${data['category_name'] ?? 'General'}: ${data['amount']} SAR\n";
      }
      Get.defaultDialog(title: "Your Report is Ready", content: SelectableText(report), confirm: TextButton(onPressed: () => Get.back(), child: const Text("Done")));
    } catch (e) { Get.snackbar("Error", "Export failed: $e"); }
  }

  Future<void> deleteNotification(String docId) async {
    if (uid == null) return;
    try { await _firestore.collection("users").doc(uid).collection("notifications").doc(docId).delete(); } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> markAsRead(String docId) async {
    if (uid == null) return;
    try { await _firestore.collection("users").doc(uid).collection("notifications").doc(docId).update({"is_read": true}); } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (uid == null) return;
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("notifications").where("is_read", isEqualTo: false).get();
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) { batch.update(doc.reference, {"is_read": true}); }
      await batch.commit();
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> deleteAllNotifications() async {
    if (uid == null) return;
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("notifications").get();
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      Get.snackbar("Deleted", "Notification history cleared");
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> logActivity({required String title, required String description, required String type, double? amount}) async {
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).collection('history').add({
        'title': title, 'description': description, 'type': type, 'amount': amount ?? 0.0, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint("Activity log error: $e"); }
  }

  /// =============================
  /// Smart Alert System
  /// =============================

  Future<void> checkBudgetUpdated(double currentSpent, double limit) async {
    if (limit <= 0) return;
    double usagePercent = (currentSpent / limit);

    if (usagePercent >= 1.0) {
      if (!_sessionAlerts.contains('main_full')) {
        _sessionAlerts.add('main_full');
        _triggerCriticalAlert();
        _showSmartSnackbar("🚨 Budget Limit Reached 100%!", "Total monthly budget has been fully consumed.", isCritical: true);
        await NotificationService().showNotification(title: "🚨 Budget Limit Reached 100%!", body: "Total monthly budget exhausted.");
        await addNotification(title: "Budget Ceiling Exceeded 🛑", body: "100% of monthly budget spent.", type: "critical");
      }
    }
    else if (usagePercent >= 0.9) {
      if (!_sessionAlerts.contains('main_90p')) {
        _sessionAlerts.add('main_90p');
        _triggerWarningAlert();
        _showSmartSnackbar("⚠️ Warning: Near Budget Limit!", "Consumed ${(usagePercent * 100).toInt()}% of budget.", isCritical: false);
        await NotificationService().showNotification(title: "⚠️ Warning: Near Budget Limit!", body: "Consumed ${(usagePercent * 100).toInt()}% of budget.");
        await addNotification(title: "90% Usage Alert ⚠️", body: "Monthly budget is almost exhausted.", type: "warning");
      }
    }
    // إضافة الشرط المطلوب لنسبة الـ 85% دون حذف أي شيء
    else if (usagePercent >= 0.85) {
      if (!_sessionAlerts.contains('main_85p')) {
        _sessionAlerts.add('main_85p');
        _triggerWarningAlert();
        _showSmartSnackbar("ℹ️ Attention: Budget over 85%!", "You have used ${(usagePercent * 100).toInt()}% of your budget.", isCritical: false);
        await addNotification(title: "85% Usage Alert ℹ️", body: "Monthly budget usage exceeded 85%.", type: "warning");
      }
    }

    await _checkAllCategoryBudgets();

    if (usagePercent < 0.85) {
      _sessionAlerts.remove('main_full');
      _sessionAlerts.remove('main_90p');
      _sessionAlerts.remove('main_85p'); // مسح تنبيه الـ 85% عند انخفاض المصاريف
    }
  }

  Future<void> _checkAllCategoryBudgets() async {
    if (uid == null) return;
    try {
      String month = DateTime.now().month.toString();
      var budgetSnapshot = await _firestore.collection('users').doc(uid).collection('budgets')
          .where('month', isEqualTo: month)
          .where('is_total', isEqualTo: false).get();

      var transSnapshot = await _firestore.collection('users').doc(uid).collection('transactions').get();

      for (var budgetDoc in budgetSnapshot.docs) {
        String catName = budgetDoc['category_name'].toString().trim();
        double limit = (budgetDoc['limit_amount'] ?? 0.0).toDouble();

        double spent = transSnapshot.docs.fold(0.0, (sum, doc) {
          var data = doc.data();
          String transCat = (data['category_name'] ?? "").toString().trim();
          if (data['type'].toString().toLowerCase() == 'expense' && (transCat == catName)) {
            return sum + (double.tryParse(data['amount'].toString()) ?? 0.0);
          }
          return sum;
        });

        _checkAndAlertCategory(catName, spent, limit);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _checkAndAlertCategory(String category, double spent, double limit) async {
    if (limit <= 0) return;
    double percent = (spent / limit) * 100;

    if (spent >= limit) {
      if (!_sessionAlerts.contains('cat_alert_$category')) {
        _sessionAlerts.add('cat_alert_$category');
        _triggerCriticalAlert();
        _showSmartSnackbar("Category Finished! 🛑", "Used 100% of $category budget.", isCritical: true);
        await NotificationService().showNotification(title: "Category Exhausted: $category", body: "Limit reached ($limit SAR).");
        await addNotification(title: "$category Limit Reached", body: "100% of $category budget spent.", type: "budget_exceeded");
      }
    }
    else if (percent >= 90) {
      if (!_sessionAlerts.contains('cat_alert_$category')) {
        _sessionAlerts.add('cat_alert_$category');
        _triggerWarningAlert();
        _showSmartSnackbar("Warning (${percent.toInt()}%) ⚠️", "$category budget is almost empty.", isCritical: false);
        await addNotification(title: "$category Near Limit", body: "$category usage reached ${percent.toInt()}%.", type: "budget_warning");
      }
    }
    // إضافة الشرط المطلوب للفئات عند تجاوز 85%
    else if (percent >= 85) {
      if (!_sessionAlerts.contains('cat_85_$category')) {
        _sessionAlerts.add('cat_85_$category');
        _triggerWarningAlert();
        _showSmartSnackbar("Note (${percent.toInt()}%) ℹ️", "$category usage crossed 85%.", isCritical: false);
        await addNotification(title: "$category Over 85%", body: "$category usage reached ${percent.toInt()}%.", type: "budget_warning");
      }
    }
    else if (percent < 85) {
      _sessionAlerts.remove('cat_alert_$category');
      _sessionAlerts.remove('cat_85_$category');
    }
  }

  void _showSmartSnackbar(String title, String message, {required bool isCritical}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        title, message,
        backgroundColor: isCritical ? Colors.redAccent : Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: Icon(isCritical ? Icons.report_problem : Icons.notifications_active, color: Colors.white),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(15),
        borderRadius: 15,
      );
    }
  }

  void _triggerWarningAlert() { HapticFeedback.heavyImpact(); SystemSound.play(SystemSoundType.click); }
  void _triggerCriticalAlert() {
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.click);
    Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.vibrate());
  }
  /// =============================
  /// CATEGORY ALERT SYSTEM (ADDED)
  /// =============================

  // هذه الدالة هي التي يشتكي الكود من عدم وجودها
  void checkAndAlertCategory(String category, double spent, double limit) async {
    if (limit <= 0) return;
    double percent = (spent / limit) * 100;

    // 1. تنبيه 100%
    if (spent >= limit) {
      if (!_sessionAlerts.contains('cat_alert_$category')) {
        _sessionAlerts.add('cat_alert_$category');
        _triggerCriticalAlert();
        _showSmartSnackbar("Category Finished! 🛑", "Used 100% of $category budget.", isCritical: true);
        await NotificationService().showNotification(
            title: "Category Exhausted: $category",
            body: "Limit reached ($limit SAR)."
        );
        await addNotification(
            title: "$category Limit Reached",
            body: "100% of $category budget spent.",
            type: "budget_exceeded"
        );
      }
    }
    // 2. تنبيه 90%
    else if (percent >= 90) {
      if (!_sessionAlerts.contains('cat_90_$category')) {
        _sessionAlerts.add('cat_90_$category');
        _triggerWarningAlert();
        _showSmartSnackbar("Warning (${percent.toInt()}%) ⚠️", "$category budget is almost empty.", isCritical: false);
        await addNotification(
            title: "$category Near Limit",
            body: "$category usage reached ${percent.toInt()}%.",
            type: "budget_warning"
        );
      }
    }
    // 3. التنبيه المطلوب: تجاوز 85%
    else if (percent >= 85) {
      if (!_sessionAlerts.contains('cat_85_$category')) {
        _sessionAlerts.add('cat_85_$category');
        _triggerWarningAlert();
        _showSmartSnackbar("Note (${percent.toInt()}%) ℹ️", "$category usage crossed 85%.", isCritical: false);
        await addNotification(
            title: "$category Over 85%",
            body: "$category usage reached ${percent.toInt()}%.",
            type: "budget_warning"
        );
      }
    }
    // إعادة ضبط التنبيهات إذا انخفض الصرف تحت 85%
    else {
      _sessionAlerts.remove('cat_alert_$category');
      _sessionAlerts.remove('cat_90_$category');
      _sessionAlerts.remove('cat_85_$category');
    }
  }
  /// =============================
  /// TRANSACTION & CATEGORY MANAGEMENT
  /// =============================
  RxList<Map<String, dynamic>> allTransactions = <Map<String, dynamic>>[].obs;
  RxBool isTransactionsLoading = true.obs;

  void listenToTransactions() {
    if (uid == null) return;

    _firestore
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {

      List<Map<String, dynamic>> tempDetails = [];
      for (var doc in snapshot.docs) {
        try {
          var data = doc.data();
          String rawType = (data['type'] ?? "").toString().toLowerCase();

          tempDetails.add({
            "id": doc.id,
            ...data,
            "type": rawType.contains('inc') ? 'Income' : 'Expense',
            "amount": double.tryParse((data["amount"] ?? 0).toString()) ?? 0.0,
            "categoryName": data['category_name'] ?? data['categoryName'] ?? 'General',
            "categoryColor": data['category_color'] ?? data['categoryColor'] ?? "0xFF1565C0",
            "categoryIcon": data['category_icon'] ?? data['categoryIcon'] ?? "57585",
          });
        } catch (e) {
          debugPrint("Error parsing doc ${doc.id}: $e");
        }
      }

      allTransactions.value = tempDetails;
      isTransactionsLoading.value = false;
    }, onError: (error) {
      debugPrint("Firestore Stream Error: $error");
      isTransactionsLoading.value = false;
    });
  }

  Future<void> updateCategoryBudget({required String categoryName, required double limit, required double spent}) async {
    if (uid == null) return;
    try {
      _checkAndAlertCategory(categoryName, spent, limit);
      String month = DateTime.now().month.toString();
      var snapshot = await _firestore.collection('users').doc(uid).collection('budgets')
          .where('category_name', isEqualTo: categoryName)
          .where('month', isEqualTo: month).get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'limit_amount': limit});
      }
      _showSuccessSnackbar("Success", "Budget for $categoryName updated");
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(title, message, backgroundColor: const Color(0xFF103667), colorText: Colors.white, snackPosition: SnackPosition.TOP);
  }

  void listenToFinancialData() {
    if (uid == null) return;
    _subscriptions.add(totalIncomeStream.listen((val) {
      if (Get.isRegistered<DashboardController>()) totalIncome.value = val;
    }));
    _subscriptions.add(totalExpenseStream.listen((val) {
      if (Get.isRegistered<DashboardController>()) {
        totalExpense.value = val;
        checkBudgetUpdated(val, monthlyBudget.value);
      }
    }));
  }

  Future<void> updateMonthlyBudget(double amount) async {
    if (uid == null) return;
    try {
      await _firestore.collection("users").doc(uid).update({"monthlyBudget": amount});
      monthlyBudget.value = amount;
      _sessionAlerts.clear();
      await checkBudgetUpdated(totalExpense.value, amount);
      Get.snackbar("Saved", "Budget limit updated successfully", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) { Get.snackbar("Error", "Update failed"); }
  }

  Future<void> checkBudget(String userId) async {
    try {
      double limit = monthlyBudget.value;
      if (limit <= 0) return;
      double usagePercent = (totalExpense.value / limit);
      if (usagePercent >= 1.0) { await NotificationService().budgetExceeded(); }
      else if (usagePercent >= 0.8) { await NotificationService().budgetWarning(usagePercent * 100); }
    } catch (e) { debugPrint("Budget check error: $e"); }
  }

  Future<void> loadBudget() async {
    if (uid == null) return;
    var doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) {
      var data = doc.data();
      monthlyBudget.value = (data?["monthlyBudget"] ?? data?["monthly_budget"] ?? 0.0).toDouble();

      Future.delayed(const Duration(seconds: 2), () {
        if (uid != null) checkBudgetUpdated(totalExpense.value, monthlyBudget.value);
      });
    }
  }

  Future<void> createDefaultCategories() async {
    if (uid == null) return;
    var ref = _firestore.collection('users').doc(uid).collection('categories');
    var snapshot = await ref.where('is_default', isEqualTo: true).get();
    if (snapshot.docs.isNotEmpty) return;
  }

  Future<void> logout() async {
    try {
      // 1. أولاً: نوقف المستمعات (Streams) يدوياً إذا كانت موجودة لمنع طلب بيانات جديدة
      // 2. ثانياً: ننتقل لصفحة اللوجن فوراً ونمسح التاريخ (Stack)
      Get.offAllNamed('/login');

      // 3. ثالثاً: تسجيل الخروج من Firebase
      await _auth.signOut();

      // 4. رابعاً: حذف المتحكمات من الذاكرة تماماً
      Get.delete<DashboardController>(force: true);
      Get.delete<GoalController>(force: true);

    } catch (e) {
      debugPrint("Logout Error: $e");
      // في حال حدث خطأ، نضمن خروج المستخدم بأي حال
      Get.offAllNamed('/login');
    }
  }

  Future<void> refreshData() async { if (uid == null) return; try { await loadBudget(); } catch (e) { debugPrint(e.toString()); } }

  Future<void> addNotification({required String title, required String body, required String type}) async {
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).collection('notifications').add({
        'title': title, 'body': body, 'type': type, 'is_read': false, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint(e.toString()); }
  }

  Stream<List<Map<String, dynamic>>> get expenseDistributionStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      Map<String, double> categories = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if ((data['type'] ?? "").toString().toLowerCase() == "expense") {
          String cat = data['category_name'] ?? data['categoryName'] ?? 'Other';
          double amt = double.tryParse(data['amount'].toString()) ?? 0.0;
          categories[cat] = (categories[cat] ?? 0) + amt;
        }
      }
      return categories.entries.map((e) => {"category": e.key, "amount": e.value}).toList();
    });
  }

  RxString selectedPeriod = 'Month'.obs;
  void changePagePeriod(String period) => selectedPeriod.value = period;

  Stream<List<FlSpot>> get dailyCashFlowStream {
    return selectedPeriod.stream.asyncExpand((period) {
      if (uid == null) return Stream.value([const FlSpot(0, 0)]);
      return _firestore.collection("users").doc(uid).collection("transactions")
          .snapshots().map((snapshot) {
        DateTime now = DateTime.now(); Map<int, double> sums = {};
        for (var doc in snapshot.docs) {
          var data = doc.data(); if (data['timestamp'] == null) continue;
          DateTime date = (data['timestamp'] as Timestamp).toDate();
          double amt = double.tryParse(data['amount'].toString()) ?? 0.0;
          bool isIncome = (data['type'] ?? "").toString().toLowerCase() == 'income';
          bool include = false; int key = 0;
          if (period == 'Week' && date.isAfter(now.subtract(const Duration(days: 7)))) { include = true; key = date.weekday; }
          else if (period == 'Month' && date.month == now.month && date.year == now.year) { include = true; key = date.day; }
          else if (period == 'Year' && date.year == now.year) { include = true; key = date.month; }
          if (include) sums[key] = (sums[key] ?? 0) + (isIncome ? amt : -amt);
        }
        List<FlSpot> spots = sums.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()..sort((a, b) => a.x.compareTo(b.x));
        return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
      });
    });
  }

  @override
  void onClose() {
    for (var sub in _subscriptions) { sub.cancel(); }
    pageController.dispose();
    super.onClose();
  }
}