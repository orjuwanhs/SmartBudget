import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../controllers/dashboard_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color textBlack = Color(0xFF000000);
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
              top: -60,
              right: -60,
              child: _buildBlurBlob([deepTeal.withOpacity(0.12), Colors.teal.shade900.withOpacity(0.08)])
          ),
          Positioned(
              bottom: -40,
              left: -70,
              child: _buildBlurBlob([deepBlue.withOpacity(0.1), Colors.blue.shade900.withOpacity(0.06)])
          ),

          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('history')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      var logs = snapshot.data!.docs;

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), // حواف ملمومة
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          var log = logs[index].data() as Map<String, dynamic>;
                          return _buildHistoryCard(log);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
          ),
          const Expanded(
            child: Text(
              "Activity History",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF103667)),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log) {
    IconData icon;
    Color color;

    switch (log['type']) {
      case 'transaction': icon = Icons.swap_vert_rounded; color = Colors.blue.shade700; break;
      case 'goal': icon = Icons.stars_rounded; color = Colors.green.shade600; break;
      case 'budget': icon = Icons.track_changes_rounded; color = Colors.redAccent; break;
      default: icon = Icons.history_rounded; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // تقليل المسافة بين البطاقات
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ملموم أكثر
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15), // زوايا أصغر وأرشق
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // تصغير حجم أيقونة النشاط
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    log['type'].toString().toUpperCase(),
                    style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  log['title'] ?? "Activity",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textBlack),
                ),
                Text(
                  log['description'] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: textBlack.withOpacity(0.4), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (log['amount'] != null)
                Text(
                  "${(log['amount'] as num).toDouble().toStringAsFixed(1)} SAR",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color),
                ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(log['timestamp']),
                style: TextStyle(fontSize: 8, color: Colors.blueAccent.withOpacity(0.6), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Text("No activities yet", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime dt = (timestamp as Timestamp).toDate();
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 100, spreadRadius: 40)]
      )
  );
}