import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _defaultIcon = 'ic_launcher';
  static const String _walletIcon = 'ic_stat_wallet';

  final Map<String, DateTime> _lastNotificationTimes = {};
  // تقليل مدة الكبح للاختبار، أو إلغاؤها للحالات الحرجة
  final Duration _throttleDuration = const Duration(seconds: 5);

  Future<void> init() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // طلب الصلاحيات بشكل صريح
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(android: androidInit);

    await notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (payload == "budget") Get.toNamed('/MonthlyBudgetScreen');
          if (payload == "transaction") Get.toNamed('/HistoryScreen');
          if (payload == "dashboard") Get.toNamed('/Home');
        }
      },
    );

    // إنشاء القناة مع تفعيل الصوت والاهتزاز بأعلى درجة
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'finance_alerts', // نفس الـ ID المستخدم في الأسفل
      'Finance Alerts',
      description: 'Important financial notifications and budget alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // دالة عرض الإشعار العام للميزانية
  Future<void> showNotification({required String title, required String body}) async {
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _show(
      id: notificationId,
      title: title,
      body: body,
      payload: "budget",
      type: "budget_critical", // تم تغيير النوع لتخطي نظام الكبح (Throttle)
      iconName: _walletIcon,
      color: const Color(0xFFFF6D00),
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String type,
    String? iconName,
    Color? color,
  }) async {

    // منطق الذكاء: لا ترسل إشعار مكرر إلا إذا كان "حرج"
    final now = DateTime.now();
    if (type == "budget_warning") {
      if (_lastNotificationTimes.containsKey(type)) {
        final lastTime = _lastNotificationTimes[type]!;
        if (now.difference(lastTime) < _throttleDuration) {
          return; // منع الإزعاج
        }
      }
      _lastNotificationTimes[type] = now;
    }

    // نمط اهتزاز قوي: [توقف، اهتزاز، توقف، اهتزاز]
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_alerts',
      'Finance Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: iconName ?? _defaultIcon,
      color: color ?? Colors.teal,
      colorized: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      styleInformation: BigTextStyleInformation(body),
      // تحديد الصوت الافتراضي للنظام لضمان العمل
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );

    NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    await _saveNotification(title: title, body: body, type: type);
  }

  Future<void> _saveNotification({required String title, required String body, required String type}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection("users").doc(uid).collection("notifications").add({
      "title": title,
      "body": body,
      "type": type,
      "is_read": false,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // استدعاء التحذيرات المباشرة
  Future<void> budgetWarning(double percent) async {
    await _show(
      id: 2002,
      title: "Budget Warning ⚠️",
      body: "You used ${percent.toStringAsFixed(0)}% of your budget",
      payload: "budget",
      type: "budget_warning",
      iconName: _walletIcon,
      color: Colors.orange,
    );
  }

  Future<void> budgetExceeded() async {
    await _show(
      id: 2003,
      title: "Budget Exceeded 🚨",
      body: "You exceeded your monthly budget",
      payload: "budget",
      type: "budget_critical", // نوع حرج لا يخضع للكبح
      iconName: _walletIcon,
      color: Colors.red,
    );
  }
  // استرجع هذه الدوال إذا كنت تستخدمها في شاشات أخرى:

  Future<void> goalCompleted(String goalName) async {
    await _show(
      id: 3002,
      title: "Goal Completed 🎉",
      body: "Congratulations! You completed $goalName",
      payload: "goal",
      type: "goal_achieved",
      iconName: _walletIcon,
      color: Colors.teal.shade700,
    );
  }

  Future<void> lowBalance(double balance) async {
    await _show(
      id: 2001,
      title: "Low Balance ⚠️",
      body: "Your balance is now $balance",
      payload: "dashboard",
      type: "budget_warning", // يخضع للكبح لمرة واحدة كل 5 ثوانٍ
      iconName: _walletIcon,
      color: Colors.orange.shade800,
    );
  }
}