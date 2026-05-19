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

    // الحل الجذري: مراقبة حالة المستخدم لضمان عدم بدء الـ Streams والـ UID فارغ
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint("User logged in: ${user.uid}. Initializing data...");
        _clearAllData(); // تنظيف أي مستمعات قديمة قبل البدء لمنع التكرار والانهيار ✨
        _startInitialTasks();
        listenToTransactions();
      } else {
        debugPrint("No active user session.");
        _clearAllData();
      }
    });
  }

  void _startInitialTasks() {
    loadBudget();
    createDefaultCategories();
    listenToFinancialData();
  }

  void _clearAllData() {
    for (var sub in _subscriptions) { sub.cancel(); }
    _subscriptions.clear();
    allTransactions.clear();
    totalIncome.value = 0.0;
    totalExpense.value = 0.0;
    monthlyBudget.value = 0.0;
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
        if (type.contains("inc")) {
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
        if (type.contains("exp")) {
          double value = double.tryParse((data["amount"] ?? data["expense_amount"] ?? 0.0).toString()) ?? 0.0;
          return sum + value;
        }
        return sum;
      });
    });
  }

  /// =============================
  /// Real-time Transactions Stream (Updated)
  /// =============================
  Stream<List<Map<String, dynamic>>> get recentTransactionsStream {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .orderBy("timestamp", descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        String rawType = (data['type'] ?? "").toString().toLowerCase();
        return {
          "id": doc.id,
          ...data,
          "type": rawType.contains('inc') ? 'Income' : 'Expense',
          "amount": double.tryParse((data["amount"] ?? 0.0).toString()) ?? 0.0,
          // جلب الأيقونة واللون من المستند (تأكد من تخزينها عند إضافة العملية)
          "categoryIcon": data['category_icon'] ?? data['categoryIcon'] ?? "",
          "categoryColor": data['category_color'] ?? data['categoryColor'] ?? "0xFF1565C0",
          "categoryName": data['category_name'] ?? data['categoryName'] ?? "General",
        };
      }).toList();
    }).asBroadcastStream(); // منع خطأ "Stream already listened to"
  }


  /// =============================
  /// CRUD Operations
  /// =============================

  Future<void> updateTransaction(String docId, Map<String, dynamic> newData) async {
    if (uid == null) return;
    try {
      if (newData.containsKey('type')) {
        String rawType = newData['type'].toString().toLowerCase();
        newData['type'] = rawType.contains('inc') ? 'Income' : 'Expense';
      }
      await _firestore.collection("users").doc(uid).collection("transactions").doc(docId).update(newData);
      HapticFeedback.mediumImpact();
      Get.snackbar("Updated", "Transaction updated successfully", backgroundColor: Colors.green, colorText: Colors.white);
      Future.delayed(const Duration(seconds: 1), () => Get.back());
    } catch (e) {
      Get.snackbar("Update Failed", "Error: ${e.toString()}", backgroundColor: Colors.redAccent);
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

  void confirmDelete(String? docId) {
    if (docId == null) return;
    Get.defaultDialog(
      title: "Confirm Delete",
      middleText: "Are you sure you want to delete this transaction?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await deleteTransaction(docId);
      },
    );
  }

  /// =============================
  /// Notification & History Management
  /// =============================

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
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
      Get.snackbar("Deleted", "Notification history cleared");
    } catch (e) { debugPrint(e.toString()); }
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
  /// Smart Alert System (Mashed & Fixed)
  /// =============================

  Future<void> checkBudgetUpdated(double currentSpent, double limit) async {
    if (limit <= 0) return;
    double usagePercent = (currentSpent / limit);

    if (usagePercent >= 1.0) {
      if (!_sessionAlerts.contains('main_full')) {
        _sessionAlerts.add('main_full');
        _triggerCriticalAlert();
        _showSmartSnackbar("🚨 Budget Exhausted!", "100% of monthly budget used.", isCritical: true);
        await NotificationService().showNotification(title: "🚨 Limit Reached!", body: "Total monthly budget exhausted.");
        await addNotification(title: "Budget Ceiling Reached 🛑", body: "100% of budget spent.", type: "critical");
      }
    }
    else if (usagePercent >= 0.85) {
      if (!_sessionAlerts.contains('main_85p')) {
        _sessionAlerts.add('main_85p');
        _triggerWarningAlert();
        _showSmartSnackbar("ℹ️ Budget over 85%!", "You used ${(usagePercent * 100).toInt()}% of your budget.", isCritical: false);
        await addNotification(title: "85% Usage Alert ℹ️", body: "Monthly budget exceeded 85%.", type: "warning");
      }
    }

    await _checkAllCategoryBudgets();

    if (usagePercent < 0.85) {
      _sessionAlerts.remove('main_full');
      _sessionAlerts.remove('main_85p');
    }
  }

  Future<void> _checkAllCategoryBudgets() async {
    if (uid == null) return;
    try {
      String month = DateTime.now().month.toString();
      var budgetSnapshot = await _firestore.collection('users').doc(uid).collection('budgets')
          .where('month', isEqualTo: month).get();

      var transSnapshot = await _firestore.collection('users').doc(uid).collection('transactions').get();

      for (var budgetDoc in budgetSnapshot.docs) {
        String catName = budgetDoc['category_name'].toString().trim();
        double limit = (budgetDoc['limit_amount'] ?? 0.0).toDouble();

        double spent = transSnapshot.docs.fold(0.0, (sum, doc) {
          var data = doc.data();
          if (data['type'].toString().toLowerCase().contains('exp') && data['category_name'] == catName) {
            return sum + (double.tryParse(data['amount'].toString()) ?? 0.0);
          }
          return sum;
        });

        checkAndAlertCategory(catName, spent, limit);
      }
    } catch (e) { debugPrint("Budget Check Error: $e"); }
  }

  void checkAndAlertCategory(String category, double spent, double limit) async {
    if (limit <= 0) return;
    double percent = (spent / limit) * 100;

    if (spent >= limit) {
      if (!_sessionAlerts.contains('cat_100_$category')) {
        _sessionAlerts.add('cat_100_$category');
        _triggerCriticalAlert();
        _showSmartSnackbar("Category Limit! 🛑", "Used 100% of $category.", isCritical: true);
        await addNotification(title: "$category Exhausted", body: "100% of $category budget spent.", type: "budget_exceeded");
      }
    }
    else if (percent >= 85) {
      if (!_sessionAlerts.contains('cat_85_$category')) {
        _sessionAlerts.add('cat_85_$category');
        _triggerWarningAlert();
        _showSmartSnackbar("Category 85% ℹ️", "$category usage crossed 85%.", isCritical: false);
        await addNotification(title: "$category over 85%", body: "$category usage reached ${percent.toInt()}%.", type: "budget_warning");
      }
    } else {
      _sessionAlerts.remove('cat_100_$category');
      _sessionAlerts.remove('cat_85_$category');
    }
  }

  void _showSmartSnackbar(String title, String message, {required bool isCritical}) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(title, message, backgroundColor: isCritical ? Colors.redAccent : Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  void _triggerWarningAlert() { HapticFeedback.heavyImpact(); SystemSound.play(SystemSoundType.click); }
  void _triggerCriticalAlert() { HapticFeedback.vibrate(); SystemSound.play(SystemSoundType.click); }

  /// =============================
  /// TRANSACTION & CATEGORY MANAGEMENT
  /// =============================
  RxList<Map<String, dynamic>> allTransactions = <Map<String, dynamic>>[].obs;
  RxBool isTransactionsLoading = true.obs;

  void listenToTransactions() {
    if (uid == null) return;
    _subscriptions.add(
        _firestore.collection("users").doc(uid).collection("transactions")
            .orderBy("timestamp", descending: true)
            .snapshots().listen((snapshot) {
          allTransactions.assignAll(snapshot.docs.map((doc) {
            var data = doc.data();
            return {
              "id": doc.id,
              ...data,
              "type": data['type'].toString().toLowerCase().contains('inc') ? 'Income' : 'Expense',
              "amount": double.tryParse(data["amount"].toString()) ?? 0.0,
            };
          }).toList());
          isTransactionsLoading.value = false;
        })
    );
  }

  Future<void> updateCategoryBudget({required String categoryName, required double limit, required double spent}) async {
    if (uid == null) return;
    try {
      checkAndAlertCategory(categoryName, spent, limit);
      String month = DateTime.now().month.toString();
      var snapshot = await _firestore.collection('users').doc(uid).collection('budgets')
          .where('category_name', isEqualTo: categoryName)
          .where('month', isEqualTo: month).get();

      if (snapshot.docs.isNotEmpty) { await snapshot.docs.first.reference.update({'limit_amount': limit}); }
      _showSuccessSnackbar("Success", "Budget for $categoryName updated");
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(title, message, backgroundColor: const Color(0xFF103667), colorText: Colors.white);
  }

  void listenToFinancialData() {
    if (uid == null) return;
    _subscriptions.add(totalIncomeStream.listen((val) => totalIncome.value = val));
    _subscriptions.add(totalExpenseStream.listen((val) {
      totalExpense.value = val;
      checkBudgetUpdated(val, monthlyBudget.value);
    }));
  }

  Future<void> updateMonthlyBudget(double amount) async {
    if (uid == null) return;
    try {
      await _firestore.collection("users").doc(uid).update({"monthlyBudget": amount});
      monthlyBudget.value = amount;
      _sessionAlerts.clear();
      checkBudgetUpdated(totalExpense.value, amount);
      Get.snackbar("Saved", "Budget limit updated successfully", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) { Get.snackbar("Error", "Update failed"); }
  }

  Future<void> loadBudget() async {
    if (uid == null) return;
    var doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) {
      var data = doc.data();
      monthlyBudget.value = (data?["monthlyBudget"] ?? data?["monthly_budget"] ?? 0.0).toDouble();
    }
  }

  Future<void> createDefaultCategories() async {
    if (uid == null) return;
    // التحقق يتم في SignUpController، هذه الدالة للضمان الإضافي
    var ref = _firestore.collection('users').doc(uid).collection('categories');
    var snapshot = await ref.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
  }

  /// =============================
  /// EXPORT & UTILS
  /// =============================

  Future<void> exportFinancialReport() async {
    if (uid == null) return;
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("transactions").orderBy("timestamp", descending: true).limit(50).get();
      if (snapshot.docs.isEmpty) { Get.snackbar("Export", "No data available"); return; }
      String report = "📊 Financial Report\n--------------------------------\n";
      for (var doc in snapshot.docs) {
        var data = doc.data();
        report += "${data['type'] == 'Income' ? '➕' : '➖'} ${data['category_name']}: ${data['amount']} SAR\n";
      }
      Get.defaultDialog(title: "Report", content: SelectableText(report), confirm: TextButton(onPressed: () => Get.back(), child: const Text("Done")));
    } catch (e) { Get.snackbar("Error", "Export failed"); }
  }

  Future<void> logout() async {
    try {
      Get.offAllNamed('/login');
      await _auth.signOut();
      _clearAllData();
      Get.delete<DashboardController>(force: true);
      Get.delete<GoalController>(force: true);
    } catch (e) {
      debugPrint("Logout Error: $e");
      Get.offAllNamed('/login');
    }
  }

  Future<void> addNotification({required String title, required String body, required String type}) async {
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).collection('notifications').add({
        'title': title, 'body': body, 'type': type, 'is_read': false, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint(e.toString()); }
  }

  /// =============================
  /// Chart Streams & Reports
  /// =============================

  Stream<List<Map<String, dynamic>>> get expenseDistributionStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      Map<String, double> categories = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if ((data['type'] ?? "").toString().toLowerCase().contains("exp")) {
          String cat = data['category_name'] ?? 'Other';
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
          bool isIncome = (data['type'] ?? "").toString().toLowerCase().contains('inc');
          bool include = false; int key = 0;
          if (period == 'Week' && date.isAfter(now.subtract(const Duration(days: 7)))) { include = true; key = date.weekday; }
          else if (period == 'Month' && date.month == now.month) { include = true; key = date.day; }
          else if (period == 'Year' && date.year == now.year) { include = true; key = date.month; }
          if (include) sums[key] = (sums[key] ?? 0) + (isIncome ? amt : -amt);
        }
        List<FlSpot> spots = sums.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()..sort((a, b) => a.x.compareTo(b.x));
        return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
      });
    });
  }
  /// =============================
  /// REFRESH DATA METHOD
  /// =============================
  Future<void> refreshData() async {
    if (uid == null) return;
    try {
      debugPrint("Refreshing dashboard data...");

      // 1. إعادة تحميل الميزانية الشهرية
      await loadBudget();

      // 2. إعادة تشغيل المستمعات لضمان تحديث البيانات
      listenToFinancialData();
      listenToTransactions();

      // 3. تحديث التنبيهات بناءً على البيانات الجديدة
      await checkBudgetUpdated(totalExpense.value, monthlyBudget.value);

      debugPrint("Dashboard refreshed successfully.");
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }
  /// =============================
  /// Chart Data (Computed for Analytics Screen)
  /// =============================

  // Get distribution of expenses by category for AI analysis
  List<Map<String, dynamic>> get expenseDistribution {
    Map<String, double> cats = {};
    for (var t in allTransactions) {
      if (t['type'].toString().toLowerCase().contains('exp')) {
        String name = t['category_name'] ?? t['category'] ?? 'Other';
        double amt = (double.tryParse(t['amount'].toString()) ?? 0.0);
        cats[name] = (cats[name] ?? 0) + amt;
      }
    }
    return cats.entries.map((e) => {"categoryName": e.key, "amount": e.value}).toList();
  }

  // Get data points for LineChart based on selectedPeriod
  List<FlSpot> get dailyCashFlowPoints {
    Map<int, double> sums = {};
    DateTime now = DateTime.now();

    for (var t in allTransactions) {
      if (t['timestamp'] == null) continue;
      DateTime d = (t['timestamp'] as Timestamp).toDate();

      bool include = false;
      int key = 0;

      if (selectedPeriod.value == 'Week' && d.isAfter(now.subtract(const Duration(days: 7)))) {
        include = true;
        key = d.weekday;
      } else if (selectedPeriod.value == 'Month' && d.month == now.month && d.year == now.year) {
        include = true;
        key = d.day;
      } else if (selectedPeriod.value == 'Year' && d.year == now.year) {
        include = true;
        key = d.month;
      }

      if (include) {
        double amt = (double.tryParse(t['amount'].toString()) ?? 0.0);
        sums[key] = (sums[key] ?? 0) + (t['type'].toString().toLowerCase().contains('inc') ? amt : -amt);
      }
    }
    if (sums.isEmpty) return [const FlSpot(0, 0)];
    return sums.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  // Stats for the selected period
  double get periodIncomeTotal => _calcSumForPeriod('inc');
  double get periodExpenseTotal => _calcSumForPeriod('exp');

  double _calcSumForPeriod(String typePart) {
    return allTransactions.where((t) {
      if (!t['type'].toString().toLowerCase().contains(typePart)) return false;
      if (t['timestamp'] == null) return false;
      DateTime d = (t['timestamp'] as Timestamp).toDate();
      DateTime now = DateTime.now();
      if (selectedPeriod.value == 'Week') return d.isAfter(now.subtract(const Duration(days: 7)));
      if (selectedPeriod.value == 'Month') return d.month == now.month && d.year == now.year;
      return d.year == now.year;
    }).fold(0.0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0));
  }

  // حساب المصروفات للشهر الحالي فقط لبطاقة الداشبورد
  double get currentMonthSpent {
    DateTime now = DateTime.now();
    return allTransactions.where((t) {
      if (!t['type'].toString().toLowerCase().contains('exp')) return false;
      if (t['timestamp'] == null) return false;
      DateTime d = (t['timestamp'] as Timestamp).toDate();
      return d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0.0));
  }

  @override
  void onClose() {
    _clearAllData();
    pageController.dispose();
    super.onClose();
  }
}