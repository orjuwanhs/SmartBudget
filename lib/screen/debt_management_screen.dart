import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/debt_controller.dart'; // تأكد من المسار

class DebtManagementScreen extends StatelessWidget {
  const DebtManagementScreen({super.key});

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final DebtController controller = Get.put(DebtController());

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // الخلفية الضبابية (نفس نمط الداشبورد)
          Positioned(top: -70, right: -70, child: _buildBlurBlob(deepTeal.withOpacity(0.12))),
          Positioned(bottom: 100, left: -80, child: _buildBlurBlob(deepBlue.withOpacity(0.1))),

          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: controller.debtsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final debts = snapshot.data ?? [];
                double totalDebt = debts.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            _buildSummaryCard(totalDebt),
                            const SizedBox(height: 25),
                            const Text(
                              "Active Debts",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),

                    debts.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildDebtCard(debts[index], controller),
                        childCount: debts.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: textBlack,
        onPressed: () => _showAddDebtDialog(context, controller),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        "DEBT TRACKER",
        style: TextStyle(color: textBlack, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF103667), Color(0xFF1565C0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: deepBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Outstanding Debt", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "SAR ${NumberFormat('#,###').format(total)}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> debt, DebtController controller) {
    DateTime? date = (debt['dueDate'] as Timestamp?)?.toDate();
    String formattedDate = date != null ? DateFormat('MMM d, yyyy').format(date) : "No Date";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.money_off_rounded, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(debt['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text("Due: $formattedDate", style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("SAR ${debt['amount']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.black12, size: 18),
                onPressed: () => controller.deleteDebt(debt['id']),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(Color color) => Container(
      width: 250, height: 250,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)])
  );

  Widget _buildEmptyState() => const Center(
    child: Text("No active debts found", style: TextStyle(color: Colors.black12, fontWeight: FontWeight.w900, fontSize: 16)),
  );

  // نافذة إضافة دين جديد (نفس نمط إضافة الأهداف)
  void _showAddDebtDialog(BuildContext context, DebtController controller) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Add New Debt", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(nameCtrl, "Lender Name", Icons.person_rounded),
            const SizedBox(height: 12),
            _buildDialogField(amountCtrl, "Amount (SAR)", Icons.account_balance_wallet_rounded, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel", style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            onPressed: () {
              if(nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                controller.addDebt(nameCtrl.text, double.parse(amountCtrl.text), DateTime.now().add(const Duration(days: 30)));
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: deepBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Save Debt", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: deepBlue, size: 20),
        filled: true, fillColor: Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}