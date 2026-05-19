import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/goal_controller.dart';
import 'package:confetti/confetti.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final GoalController controller = Get.put(GoalController());
  late ConfettiController _confettiController;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  final TextEditingController addAmountController = TextEditingController();
  RxInt selectedColor = 0xFF00C853.obs;

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color textBlack = Color(0xFF000000);
  static const Color bgLight = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    nameController.dispose();
    targetController.dispose();
    addAmountController.dispose();
    super.dispose();
  }

  // دالة مساعدة لإرسال الإشعارات إلى الفايربيس (تستخدم في شاشة التنبيهات لاحقاً)
  Future<void> _sendNotification(String title, String body) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      resizeToAvoidBottomInset: true,
      appBar: _buildCompactAppBar(),
      body: Stack(
        children: [
          Positioned(top: -50, right: -30, child: _buildBlurBlob(deepTeal.withOpacity(0.06))),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: controller.goalsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              final goals = snapshot.data ?? [];
              double totalSaved = goals.fold(0.0, (sum, item) => sum + (item['saved'] ?? 0.0));

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildCompactHeaderStats(totalSaved, goals.length)),
                  if (goals.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    _buildCompactGoalsList(goals),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.teal, Colors.amber, Colors.blue],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 50,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
        onPressed: () => Get.back(),
      ),
      title: const Text("GOALS", style: TextStyle(color: textBlack, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      actions: [
        IconButton(
          onPressed: () => _showAddGoalDialog(context),
          icon: const Icon(Icons.add_circle_outline_rounded, color: deepTeal, size: 24),
        )
      ],
    );
  }

  Widget _buildCompactHeaderStats(double saved, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 15),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF103667), Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactStat(label: "Total Saved", value: "${saved.toInt()} SAR"),
          Container(width: 1, height: 25, color: Colors.white12),
          _CompactStat(label: "Goals", value: count.toString()),
        ],
      ),
    );
  }

  Widget _buildCompactGoalsList(List<Map<String, dynamic>> goals) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final goal = goals[index];
        double target = (goal['target'] ?? 1.0).toDouble();
        double saved = (goal['saved'] ?? 0.0).toDouble();
        double progress = (saved / target).clamp(0.0, 1.0);
        bool isFull = progress >= 1.0;
        Color goalColor = Color(int.parse(goal['color'].toString()));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isFull ? Colors.amber.withOpacity(0.3) : Colors.transparent, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5)],
          ),
          child: InkWell(
            onTap: () {
              _showHistoryDialog(context, goal['id'], goal['name'] ?? "Goal");
              if (isFull) _confettiController.play();
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Icon(isFull ? Icons.emoji_events_rounded : Icons.stars_rounded, color: isFull ? Colors.amber : goalColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal['name'] ?? "Goal", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          Text("Target: ${target.toInt()} SAR", style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (!isFull)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_box_rounded, color: deepBlue, size: 20),
                        onPressed: () => _showUpdateAmountDialog(context, goal['id'], goal['name']),
                      )
                    else
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),

                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: () => _confirmDelete(goal['id'], goal['name']),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black.withOpacity(0.03),
                    color: isFull ? Colors.amber : goalColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Saved: ${saved.toInt()} SAR", style: TextStyle(color: isFull ? Colors.amber.shade700 : Colors.black45, fontWeight: FontWeight.bold, fontSize: 10)),
                    Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                )
              ],
            ),
          ),
        );
      }, childCount: goals.length),
    );
  }

  Widget _buildBlurBlob(Color color) => Container(
      width: 200, height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)])
  );

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("New Goal", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(nameController, "Name", Icons.edit_rounded),
            const SizedBox(height: 10),
            // تم تغيير الأيقونة هنا لتكون نص العملة "SAR"
            _buildField(targetController, "Target Amount", null, isNumber: true, isCurrency: true),
            const SizedBox(height: 15),
            _buildColorPicker(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel", style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            onPressed: _submitGoal,
            style: ElevatedButton.styleFrom(backgroundColor: deepBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(BuildContext context, String goalId, String goalName) {
    addAmountController.clear();
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: controller.goalsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final goal = snapshot.data!.firstWhere((g) => g['id'] == goalId);
            double remaining = (goal['target'] ?? 0.0) - (goal['saved'] ?? 0.0);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Save for $goalName", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Remaining: ${remaining.toInt()} SAR", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 15),
                  _buildField(addAmountController, "Amount", Icons.add_moderator_rounded, isNumber: true),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    double val = double.tryParse(addAmountController.text) ?? 0;

                    if (val > 0) {
                      if (val > remaining) {
                        // تنبيه إذا كان المبلغ المدخل أكبر من المتبقي
                        Get.snackbar(
                          "Wait!",
                          "The amount is too large. You only need ${remaining.toInt()} SAR to complete this goal.",
                          backgroundColor: Colors.amber.shade100,
                          colorText: Colors.black,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        // إرسال إشعار صامت للـ NotificationsScreen
                        _sendNotification("Goal Update", "You added ${val.toInt()} SAR to '$goalName'");

                        controller.addMoneyToGoal(goalId, val);
                        Get.back();

                        // إذا اكتمل الهدف
                        if (val == remaining) {
                          _confettiController.play();
                          HapticFeedback.heavyImpact();
                          _showCompletionDialog(goalName);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: deepBlue),
                  child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
      ),
    );
  }

  // رسالة المباركة عند اكتمال الهدف
  void _showCompletionDialog(String goalName) {
    _sendNotification("Goal Achieved! 🎉", "Congratulations! You've reached your target for '$goalName'");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.celebration_rounded, color: Colors.amber, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Congratulations!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text("You've successfully completed your goal for '$goalName'.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, String goalId, String goalName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$goalName Logs", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        content: SizedBox(
          width: double.maxFinite, height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('savings_goals').doc(goalId).collection('history').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  DateTime d = (doc['date'] as Timestamp).toDate();
                  return ListTile(
                    dense: true,
                    title: Text("${doc['amountAdded']} SAR", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text("${d.day}/${d.month} - ${d.hour}:${d.minute}", style: const TextStyle(fontSize: 10)),
                    trailing: Text("${doc['status']}", style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData? icon, {bool isNumber = false, bool isCurrency = false}) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: isCurrency
              ? const Padding(padding: EdgeInsets.all(12), child: Text("SAR", style: TextStyle(color: deepBlue, fontWeight: FontWeight.w900, fontSize: 10)))
              : Icon(icon, size: 18, color: deepBlue),
          filled: true, fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    List<int> colors = [0xFF00C853, 0xFF1565C0, 0xFFFF6D00, 0xFFD50000, 0xFFAA00FF];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((c) => GestureDetector(
        onTap: () => selectedColor.value = c,
        child: Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 25, height: 25,
          decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: selectedColor.value == c ? Colors.black : Colors.transparent, width: 2)),
        )),
      )).toList(),
    );
  }

  void _submitGoal() {
    if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
      controller.createGoal(name: nameController.text, target: double.parse(targetController.text), icon: "62402", color: selectedColor.value.toString());
      nameController.clear(); targetController.clear(); Get.back();
    }
  }

  void _confirmDelete(String goalId, String goalName) {
    Get.defaultDialog(
        title: "Delete?",
        middleText: "Remove '$goalName'?",
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        textConfirm: "Delete", textCancel: "Back",
        confirmTextColor: Colors.white, buttonColor: Colors.redAccent,
        onConfirm: () { controller.deleteGoal(goalId); Get.back(); }
    );
  }

  Widget _buildEmptyState() => Center(child: Text("No goals set", style: TextStyle(color: Colors.black12, fontWeight: FontWeight.bold)));
}

class _CompactStat extends StatelessWidget {
  final String label, value;
  const _CompactStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))]);
}