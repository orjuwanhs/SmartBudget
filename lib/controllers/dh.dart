import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // ضروري لتعريف FlSpot
import 'package:flutter/services.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// =============================
  /// Navigation & UI States
  /// =============================
  PageController pageController = PageController();
  RxInt currentIndex = 0.obs;
  RxBool isSoundEnabled = true.obs;

  void changePage(int index) {
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// =============================
  /// Notifications Stream
  /// =============================
  Stream<int> get unreadNotificationsCountStream {
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

  String get uid => _auth.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    loadBudget();
    createDefaultCategories();
    listenToFinancialData();
  }


  /// =============================
  /// Data Streams
  /// =============================
  Stream<UserModel> get userDataStream {
    return _firestore.collection("users").doc(uid).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  /// مصلح: حساب الدخل الإجمالي
  /// =============================
  Stream<double> get totalIncomeStream {
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
  /// مصلح: حساب المصاريف الإجمالية
  /// =============================
  Stream<double> get totalExpenseStream {
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      return snapshot.docs.fold(0.0, (sum, doc) {
        var data = doc.data();
        // جعل التحقق مرن (يتقبل Expense أو expense)
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
    return _firestore.collection("users").doc(uid).collection("transactions")
        .orderBy("timestamp", descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();

        // 1. توحيد النوع لضمان عمل الألوان (Income / Expense)
        String rawType = (data['type'] ?? "").toString().toLowerCase();
        String formattedType = rawType.contains('inc') ? 'Income' : 'Expense';

        return {
          "id": doc.id,
          ...data,
          "type": formattedType, // نرسله للواجهة بتنسيق موحد

          // 2. توحيد اسم التصنيف
          "categoryName": data['category_name'] ?? data['categoryName'] ?? 'General',

          // 3. توحيد الأيقونة واللون (حل مشكلة عدم ظهور الأيقونات)
          "categoryIcon": data['category_icon'] ?? data['categoryIcon'],
          "categoryColor": data['category_color'] ?? data['categoryColor'],

          // 4. معالجة المبلغ بدقة
          "amount": double.tryParse((
              data["amount"] ??
                  data["income_amount"] ??
                  data["expense_amount"] ??
                  0.0
          ).toString()) ?? 0.0,
        };
      }).toList();
    });
  }
  Future<void> updateTransaction(String docId, Map<String, dynamic> newData) async {
    try {
      print("Attempting to update doc: $docId with data: $newData"); // للتأكد في الـ Debug Console

      // توحيد النوع لضمان عمل الألوان
      if (newData.containsKey('type')) {
        String rawType = newData['type'].toString().toLowerCase();
        newData['type'] = rawType.contains('inc') ? 'Income' : 'Expense';
      }

      await _firestore
          .collection("users")
          .doc(uid)
          .collection("transactions")
          .doc(docId)
          .update(newData);

      // إرسال اهتزاز نجاح
      HapticFeedback.mediumImpact();

      // إظهار رسالة النجاح بشكل بارز
      Get.snackbar(
        "Updated",
        "Transaction updated successfully",
        snackPosition: SnackPosition.TOP, // غيرها لـ TOP لتكون أوضح
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );

      // العودة للشاشة السابقة بعد ثانية واحدة من النجاح
      Future.delayed(const Duration(seconds: 1), () => Get.back());

    } catch (e) {
      print("Update Error: $e"); // سيظهر لك الخطأ الحقيقي هنا في الـ Console

      Get.snackbar(
        "Update Failed",
        "Error: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
  Future<void> deleteTransaction(String docId) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .collection("transactions")
          .doc(docId)
          .delete();

      // لا نحتاج لرسالة سناك بار هنا لأننا اخترنا الحذف السلس (Seamless) بالسحب
      debugPrint("Transaction $docId deleted successfully");

    } catch (e) {
      Get.snackbar("Error", "Failed to delete: $e");
    }
  }
  void _confirmDelete(String? docId) {
    if (docId == null) return;

    // تعريف الكنترولر لكي لا يظهر خطأ Undefined name
    final DashboardController controller = Get.find<DashboardController>();

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
        Get.back(); // إغلاق النافذة
        await controller.deleteTransaction(docId); // استدعاء دالة الحذف
      },
    );
  }
  /// =============================
  /// Notifications Management
  /// =============================
  /// =============================
  /// ميزة تصدير البيانات بنص منسق
  /// =============================
  Future<void> exportFinancialReport() async {
    try {
      // جلب آخر 50 عملية
      var snapshot = await _firestore.collection("users").doc(uid).collection("transactions")
          .orderBy("timestamp", descending: true).limit(50).get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar("Export", "No data available to export");
        return;
      }

      String report = "📊 Financial Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n";
      report += "--------------------------------\n";

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String type = data['type'] == 'Income' ? "➕" : "➖";
        report += "$type ${data['category_name'] ?? 'General'}: ${data['amount']} SAR\n";
      }

      report += "--------------------------------\n";
      report += "Total Income: ${totalIncome.value} SAR\n";
      report += "Total Expense: ${totalExpense.value} SAR\n";
      report += "Net Balance: ${totalIncome.value - totalExpense.value} SAR\n";

      // هنا يمكنك استخدام Share.share(report); إذا أضفت مكتبة share_plus
      // حالياً سنعرضها في سجل الكونسول ونظهر رسالة نجاح
      debugPrint(report);
      Get.defaultDialog(
          title: "Your Report is Ready",
          content: SelectableText(report),
          confirm: TextButton(onPressed: () => Get.back(), child: const Text("Done"))
      );

    } catch (e) {
      Get.snackbar("Error", "Export failed: $e");
    }
  }
  // ⭐ الميزة الجديدة: حذف إشعار محدد عند السحب
  Future<void> deleteNotification(String docId) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  Future<void> markAsRead(String docId) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(docId)
          .update({"is_read": true});
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("notifications")
          .where("is_read", isEqualTo: false).get();
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {"is_read": true});
      }
      await batch.commit();
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> deleteAllNotifications() async {
    try {
      var snapshot = await _firestore.collection("users").doc(uid).collection("notifications").get();
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
      Get.snackbar("Deleted", "Notification history cleared");
    } catch (e) { debugPrint(e.toString()); }
  }

  /// =============================
  /// Activity Log & Budget Check
  /// =============================
  Future<void> logActivity({required String title, required String description, required String type, double? amount}) async {
    try {
      await _firestore.collection('users').doc(uid).collection('history').add({
        'title': title,
        'description': description,
        'type': type,
        'amount': amount ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint("Activity log error: $e"); }
  }
// دالة فحص الميزانية مع الصوت والاهتزاز والحفظ الدائم
// Checks the budget status with sound, vibration, and persistent logging
  Future<void> checkBudgetUpdated(double currentSpent, double limit) async {
    if (limit <= 0) return;
    double usagePercent = (currentSpent / limit);

    if (usagePercent >= 1.0) {
      // CASE 100%: Continuous vibration + sound + persistent critical notification
      _triggerCriticalAlert();

      await NotificationService().showNotification(
        title: "🚨 Budget Limit Reached 100%!",
        body: "You have reached your maximum limit of (${limit.toInt()} SAR).",
      );

      await addNotification(
        title: "Budget Ceiling Exceeded 🛑",
        body: "Your total monthly budget of ${currentSpent.toInt()} SAR has been fully consumed.",
        type: "critical",
      );
    }
    else if (usagePercent >= 0.9) {
      // CASE 90%: Heavy impact + sound + persistent warning notification
      _triggerWarningAlert();

      await NotificationService().showNotification(
        title: "⚠️ Warning: Near Budget Limit!",
        body: "You have consumed ${(usagePercent * 100).toInt()}% of your monthly budget.",
      );

      await addNotification(
        title: "90% Usage Alert ⚠️",
        body: "Your budget is almost exhausted. Very little remains for this month.",
        type: "warning",
      );
    }
  }

  // Warning alerts for 90% usage
  void _triggerWarningAlert() {
    HapticFeedback.heavyImpact(); // Strong physical tap
    SystemSound.play(SystemSoundType.click);
  }

  // Critical alerts for 100% usage
  void _triggerCriticalAlert() {
    HapticFeedback.vibrate(); // Long continuous vibration
    SystemSound.play(SystemSoundType.click);

    // Slight delay followed by another vibration for maximum attention
    Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.vibrate());
  }

  /// =============================
  /// UPDATED CORE FUNCTIONS
  /// =============================

  @override
  void listenToFinancialData() {
    totalIncomeStream.listen((val) => totalIncome.value = val);
    totalExpenseStream.listen((val) {
      totalExpense.value = val;
      // Automatically check budget whenever a new expense occurs
      checkBudgetUpdated(val, monthlyBudget.value);
    });
  }

  // Updated function to include immediate status check after limit change
  Future<void> updateMonthlyBudget(double amount) async {
    try {
      await _firestore.collection("users").doc(uid).update({"monthlyBudget": amount});
      monthlyBudget.value = amount;

      // Check status immediately after the limit is updated
      await checkBudgetUpdated(totalExpense.value, amount);

      Get.snackbar(
          "Saved",
          "Budget limit updated successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP
      );
    } catch (e) {
      Get.snackbar(
          "Error",
          "Update failed",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white
      );
    }
  }

  Future<void> checkBudget(String userId) async {
    try {
      double limit = monthlyBudget.value;
      if (limit <= 0) return;
      double usagePercent = (totalExpense.value / limit);

      if (usagePercent >= 1.0) {
        await NotificationService().budgetExceeded();
      } else if (usagePercent >= 0.8) {
        await NotificationService().budgetWarning(usagePercent * 100);
      }
    } catch (e) {
      debugPrint("Budget check error: $e");
    }
  }

  /// =============================
  /// Budget Setup
  /// =============================
  Future<void> loadBudget() async {
    var doc = await _firestore.collection("users").doc(uid).get();
    if (doc.exists) {
      var data = doc.data();
      monthlyBudget.value = (data?["monthlyBudget"] ?? data?["monthly_budget"] ?? 0.0).toDouble();
    }
  }



  /// =============================
  /// Categories & Settings
  /// =============================
  Future<void> createDefaultCategories() async {
    var ref = _firestore.collection('users').doc(uid).collection('categories');
    var snapshot = await ref.where('is_default', isEqualTo: true).get();
    if (snapshot.docs.isNotEmpty) return;
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/Login');
  }

  /// =============================
  /// Refresh Logic
  /// =============================
  Future<void> refreshData() async {
    try {
      await loadBudget();
    } catch (e) { debugPrint("Error refreshing data: $e"); }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint("Error adding notification: $e"); }
  }
  /// جلب توزيع المصاريف حسب التصنيف للرسم البياني
  Stream<List<Map<String, dynamic>>> get expenseDistributionStream {
    return _firestore.collection("users").doc(uid).collection("transactions")
        .snapshots().map((snapshot) {
      Map<String, double> categories = {};

      for (var doc in snapshot.docs) {
        var data = doc.data();
        // إصلاح: التأكد من نوع العملية بشكل مرن
        String type = (data['type'] ?? "").toString().toLowerCase();

        if (type == "expense") {
          String cat = data['category_name'] ?? data['categoryName'] ?? 'Other';
          double amt = double.tryParse(data['amount'].toString()) ?? 0.0;
          categories[cat] = (categories[cat] ?? 0) + amt;
        }
      }
      return categories.entries.map((e) => {"category": e.key, "amount": e.value}).toList();
    });
  }
  /// =============================
  /// دالة جلب بيانات التدفق النقدي اليومي
  /// =============================
// أضف هذه المتغيرات في الكنترولر
  RxString selectedPeriod = 'Month'.obs; // الافتراضي هو الشهر

// دالة لتغيير الفترة
  void changePeriod(String period) {
    selectedPeriod.value = period;
  }

// تعديل دالة الستريم لتصبح متجاوبة مع الفترة
  Stream<List<FlSpot>> get dailyCashFlowStream {
    // نستخدم selectedPeriod.stream لجعل الستريم يستجيب فوراً عند تغيير الزر (Week/Month/Year)
    return selectedPeriod.stream.asyncExpand((period) {
      return _firestore.collection("users").doc(uid).collection("transactions")
          .snapshots().map((snapshot) {

        DateTime now = DateTime.now();
        Map<int, double> sums = {};

        for (var doc in snapshot.docs) {
          var data = doc.data();
          if (data['timestamp'] == null) continue;

          DateTime date = (data['timestamp'] as Timestamp).toDate();
          double amt = double.tryParse(data['amount'].toString()) ?? 0.0;

          // إصلاح: جعل المقارنة غير حساسة لحالة الأحرف
          String type = (data['type'] ?? "").toString().toLowerCase();
          bool isIncome = type == 'income';

          bool include = false;
          int key = 0;

          if (period == 'Week') {
            if (date.isAfter(now.subtract(const Duration(days: 7)))) {
              include = true;
              key = date.weekday;
            }
          } else if (period == 'Month') {
            if (date.month == now.month && date.year == now.year) {
              include = true;
              key = date.day;
            }
          } else if (period == 'Year') {
            if (date.year == now.year) {
              include = true;
              key = date.month;
            }
          }

          if (include) {
            sums[key] = (sums[key] ?? 0) + (isIncome ? amt : -amt);
          }
        }

        List<FlSpot> spots = sums.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList()..sort((a, b) => a.x.compareTo(b.x));

        return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
      });
    });
  }
  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}