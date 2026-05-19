import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ضروري لتنسيق الوقت بشكل احترافي
import '../controllers/dashboard_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // خلفية فاتحة ومريحة
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0.5, // ظل خفيف جداً لإعطاء عمق
        centerTitle: true,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.markAllNotificationsAsRead(),
            child: const Text("Mark all read",
                style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 24),
            onPressed: () => _confirmDeleteAll(controller),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1565C0)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // مساحة إضافية بالأسفل للسكرول
            itemCount: notifications.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              var doc = notifications[index];
              var data = doc.data() as Map<String, dynamic>;

              // معالجة الوقت بشكل احترافي
              DateTime time = (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate();
              String formattedTime = DateFormat('hh:mm a').format(time);
              String formattedDate = DateFormat('MMM dd, yyyy').format(time);

              IconData icon;
              Color color;

              // تحديد الأيقونة واللون بناءً على النوع
              switch (data['type']) {
                case 'critical':
                case 'budget_exceeded': icon = Icons.report_problem_rounded; color = Colors.redAccent; break;
                case 'warning':
                case 'budget_warning': icon = Icons.info_outline_rounded; color = Colors.orangeAccent; break;
                case 'goal_achieved': icon = Icons.emoji_events_rounded; color = Colors.amber; break;
                case 'transaction_alert': icon = Icons.account_balance_wallet_outlined; color = Colors.blueAccent; break;
                default: icon = Icons.notifications_none_rounded; color = Colors.blueGrey;
              }

              bool isUnread = !(data['is_read'] ?? true);

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  controller.deleteNotification(doc.id);
                },
                background: _buildDeleteBackground(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (isUnread) controller.markAsRead(doc.id);
                      _showNotificationDetails(context, data, formattedTime, formattedDate, icon, color);
                    },
                    child: _buildNotificationItem(
                      title: data['title'] ?? "System Alert",
                      body: data['body'] ?? "Tap to view details.",
                      time: formattedTime,
                      icon: icon,
                      color: color,
                      isUnread: isUnread,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // خلفية الحذف عند السحب
  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
    );
  }

  // تصميم عنصر الإشعار في القائمة
  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color color,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUnread ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                          color: isUnread ? Colors.black : Colors.black54,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(time, style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body,
                  style: TextStyle(
                    color: isUnread ? Colors.black87 : Colors.black45,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  // نافذة تفاصيل الإشعار (BottomSheet)
  void _showNotificationDetails(BuildContext context, Map<String, dynamic> data, String time, String date, IconData icon, Color color) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 20),
            Text(data['title'] ?? "Notification",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 12),
            Text(date + " • " + time, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[100]),
            const SizedBox(height: 20),
            Text(data['body'] ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6)),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF103667),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () => Get.back(),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // تأكيد حذف الكل
  void _confirmDeleteAll(DashboardController controller) {
    Get.defaultDialog(
      title: "Clear History",
      middleText: "This will remove all notifications permanently.",
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      middleTextStyle: const TextStyle(fontSize: 14, color: Colors.black54),
      radius: 20,
      contentPadding: const EdgeInsets.all(20),
      textCancel: "Cancel", textConfirm: "Clear All",
      confirmTextColor: Colors.white, buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteAllNotifications();
        Get.back();
      },
    );
  }

  // حالة الصفحة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          const Text("All Caught Up!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("You don't have any notifications right now.", style: TextStyle(color: Colors.black38, fontSize: 13)),
        ],
      ),
    );
  }
}