import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/dashboard_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ربط الكنترول
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        actions: [
          // زر تحديد الكل كمقروء
          TextButton(
            onPressed: () => controller.markAllNotificationsAsRead(),
            child: const Text("Mark all as read",
                style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
          ),
          // زر حذف جميع الإشعارات
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDeleteAll(controller),
            tooltip: "Clear All",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // سحب الإشعارات الحقيقية من قاعدة البيانات
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var data = notifications[index].data() as Map<String, dynamic>;
              DateTime time = (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate();

              // تحديد الأيقونة واللون بناءً على نوع الإشعار
              IconData icon;
              Color color;
              // Inside ListView.builder in NotificationsScreen
              switch (data['type']) {
                case 'goal_achieved':
                  icon = Icons.stars_rounded;
                  color = Colors.green;
                  break;
                case 'budget_alert': // سيظهر هنا تنبيه الرصيد الصفر والمنخفض
                  icon = Icons.warning_amber_rounded;
                  color = Colors.orange;
                  break;
                case 'transaction_alert': // تنبيه العمليات العادي
                  icon = Icons.account_balance_wallet_rounded;
                  color = Colors.blue;
                  break;
                default:
                  icon = Icons.notifications_active_rounded;
                  color = Colors.blueGrey;
              }

              return _buildNotificationItem(
                title: data['title'] ?? "Notification",
                body: data['body'] ?? "",
                time: "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                icon: icon,
                color: color,
                isUnread: !(data['isRead'] ?? true),
              );
            },
          );
        },
      ),
    );
  }

  // نافذة تأكيد حذف الكل
  void _confirmDeleteAll(DashboardController controller) {
    Get.defaultDialog(
      title: "Clear All?",
      middleText: "Are you sure you want to delete all notifications?",
      textCancel: "Cancel",
      textConfirm: "Delete All",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteAllNotifications();
        Get.back();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("No notifications yet", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color color,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnread
            ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        border: isUnread ? Border.all(color: color.withOpacity(0.1), width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                    Text(time, style: const TextStyle(color: Colors.black26, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(body,
                    style: TextStyle(color: isUnread ? Colors.black87 : Colors.black45, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 5),
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}