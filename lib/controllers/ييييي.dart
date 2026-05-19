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

  // إدارة الاشتراكات ومنع التعليق
  final List<StreamSubscription> _subscriptions = [];
  final Set<String> _sessionAlerts = {};

  /// =============================
  /// Navigation & UI States
  /// =============================
  PageController pageController = PageController();
  RxInt currentIndex = 0.obs;
  RxBool isSoundEnabled = true.obs;
  RxBool isTransactionsLoading = true.obs;
  RxList<Map<String, dynamic>> allTransactions = <Map<String, dynamic>>[].obs;

  void changePage(int index) {
    currentIndex.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
      );
    }
  }

  /// =============================
  /// Financial Observables
  /// =============================
  RxDouble totalBalance = 0.0.obs;
  RxDouble monthlyBudget = 0.0.obs;
  RxDouble totalIncome = 0.0.obs;
  RxDouble totalExpense = 0.0.obs;
  RxString selectedPeriod = 'Month'.obs;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (uid != null) {
      _startInitialTasks();
    }
  }

  void _startInitialTasks() {
    fetchFinancialData();
    loadBudget();
    createDefaultCategories();
    listenToFinancialData();
    listenToTransactions();
  }

  /// =============================
  /// Data Streams (إعادة RecentTransactionsStream)
  /// =============================
  Stream<List<Map<String, dynamic>>> get recentTransactionsStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .orderBy("timestamp", descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          "id": doc.id,
          ...data,
          "amount": double.tryParse(data["amount"].toString()) ?? 0.0,
        };
      }).toList();
    });
  }

  Stream<UserModel> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _firestore.collection("users").doc(uid).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Stream<double> get totalIncomeStream {
    if (uid == null) return Stream.value(0.0);
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      return snapshot.docs.fold(0.0, (sum, doc) {
        if (doc.data()["type"].toString().toLowerCase().contains('inc')) {
          return sum + (double.tryParse(doc.data()["amount"].toString()) ?? 0.0);
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
        if (doc.data()["type"].toString().toLowerCase().contains('exp')) {
          return sum + (double.tryParse(doc.data()["amount"].toString()) ?? 0.0);
        }
        return sum;
      });
    });
  }

  /// =============================
  /// Transaction Management (إعادة الحذف والتحديث)
  /// =============================
  Future<void> deleteTransaction(String docId) async {
    if (uid == null) return;
    try {
      await _firestore.collection("users").doc(uid).collection("transactions").doc(docId).delete();
      Get.snackbar("Success", "Transaction deleted", backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Delete failed: $e");
    }
  }

  Future<void> updateMonthlyBudget(double amount) async {
    if (uid == null) return;
    try {
      await _firestore.collection("users").doc(uid).update({"monthlyBudget": amount});
      monthlyBudget.value = amount;
      _sessionAlerts.clear();
      Get.snackbar("Saved", "Budget updated", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Update failed");
    }
  }

  Future<void> refreshData() async {
    if (uid == null) return;
    await fetchFinancialData();
    await loadBudget();
  }

  /// =============================
  /// Notifications & Cleanup (إعادة مسح الكل)
  /// =============================
  Future<void> deleteAllNotifications() async {
    if (uid == null) return;
    try {
      var snap = await _firestore.collection('users').doc(uid).collection('notifications').get();
      WriteBatch batch = _firestore.batch();
      for (var doc in snap.docs) { batch.delete(doc.reference); }
      await batch.commit();
      Get.snackbar("Cleared", "All notifications deleted", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      debugPrint("Delete all error: $e");
    }
  }

  // ... (بقية الدوال: Charts, Alerts, Logs) ...

  void changePagePeriod(String period) {
    selectedPeriod.value = period;
    update();
  }

  Stream<List<FlSpot>> get dailyCashFlowStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection('users').doc(uid).collection('transactions').orderBy('timestamp', descending: false).snapshots().map((snapshot) {
      List<FlSpot> spots = []; double balance = 0; int index = 0;
      for (var doc in snapshot.docs) {
        var data = doc.data(); double amt = (double.tryParse(data['amount'].toString()) ?? 0.0);
        balance += data['type'].toString().toLowerCase().contains('inc') ? amt : -amt;
        spots.add(FlSpot(index.toDouble(), balance)); index++;
      }
      return spots;
    });
  }

  Stream<List<Map<String, dynamic>>> get expenseDistributionStream {
    if (uid == null) return Stream.value([]);
    return _firestore.collection('users').doc(uid).collection('transactions').snapshots().map((snapshot) {
      Map<String, double> categories = {};
      for (var doc in snapshot.docs) {
        if (doc.data()['type'].toString().toLowerCase().contains('exp')) {
          String cat = doc.data()['category_name'] ?? 'Other';
          categories[cat] = (categories[cat] ?? 0) + (double.tryParse(doc.data()['amount'].toString()) ?? 0.0);
        }
      }
      return categories.entries.map((e) => {"category": e.key, "amount": e.value}).toList();
    });
  }

  Future<void> fetchFinancialData() async {
    if (uid == null) return;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        totalBalance.value = (data['total_balance'] ?? data['balance'] ?? 0.0).toDouble();
        monthlyBudget.value = (data['monthlyBudget'] ?? 0.0).toDouble();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void listenToTransactions() {
    if (uid == null) return;
    var sub = _firestore.collection("users").doc(uid).collection("transactions").orderBy("timestamp", descending: true).snapshots().listen((snapshot) {
      allTransactions.assignAll(snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList());
      isTransactionsLoading.value = false;
    });
    _subscriptions.add(sub);
  }

  Future<void> addNotification({required String title, required String body, required String type}) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('notifications').add({
      'title': title, 'body': body, 'type': type, 'is_read': false, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String docId) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('notifications').doc(docId).update({'is_read': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    if (uid == null) return;
    var snap = await _firestore.collection('users').doc(uid).collection('notifications').where('is_read', isEqualTo: false).get();
    WriteBatch batch = _firestore.batch();
    for (var doc in snap.docs) { batch.update(doc.reference, {'is_read': true}); }
    await batch.commit();
  }

  Future<void> deleteNotification(String docId) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('notifications').doc(docId).delete();
  }

  Future<void> logActivity({required String title, required String description, required String type, double? amount}) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('history').add({
      'title': title, 'description': description, 'type': type, 'amount': amount ?? 0.0, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void listenToFinancialData() {
    if (uid == null) return;
    _subscriptions.add(totalIncomeStream.listen((val) => totalIncome.value = val));
    _subscriptions.add(totalExpenseStream.listen((val) {
      totalExpense.value = val;
      checkBudgetUpdated(val, monthlyBudget.value);
    }));
  }

  Future<void> loadBudget() async {
    if (uid == null) return;
    var doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) monthlyBudget.value = (doc.data()?["monthlyBudget"] ?? 0.0).toDouble();
  }

  Future<void> createDefaultCategories() async {
    if (uid == null) return;
    var ref = _firestore.collection('users').doc(uid).collection('categories');
    var snap = await ref.limit(1).get();
    if (snap.docs.isEmpty) {
      await ref.add({'name': 'Food', 'is_default': true, 'color': '0xFF4CAF50', 'icon': 57585, 'type': 'expense'});
      await ref.add({'name': 'Salary', 'is_default': true, 'color': '0xFF2196F3', 'icon': 57585, 'type': 'income'});
    }
  }

  Future<void> checkBudgetUpdated(double currentSpent, double limit) async {
    if (limit <= 0) return;
    double usage = currentSpent / limit;
    if (usage >= 1.0 && !_sessionAlerts.contains('full')) {
      _sessionAlerts.add('full');
      await addNotification(title: "Budget 100%", body: "Limit reached", type: "critical");
    } else if (usage >= 0.85 && !_sessionAlerts.contains('85p')) {
      _sessionAlerts.add('85p');
      await addNotification(title: "Budget 85%", body: "Usage over 85%", type: "warning");
    }
  }

  Future<void> logout() async {
    for (var sub in _subscriptions) { await sub.cancel(); }
    await _auth.signOut();
    Get.delete<DashboardController>(force: true);
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    for (var sub in _subscriptions) { sub.cancel(); }
    pageController.dispose();
    super.onClose();
  }
}