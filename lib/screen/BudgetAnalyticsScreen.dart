import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/budget_controller.dart';

class BudgetAnalyticsScreen extends StatelessWidget {
  const BudgetAnalyticsScreen({super.key});

  static const Color deepBlue = Color(0xFF103667);
  static const Color accentTeal = Color(0xFF23857B);

  // ميثود متجاوبة لتصغير الخطوط
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  Color _parseColor(dynamic colorData) {
    if (colorData is int) return Color(colorData);
    if (colorData != null) {
      return Color(int.tryParse(colorData.toString()) ?? 0xFF103667);
    }
    return deepBlue;
  }

  @override
  Widget build(BuildContext context) {
    final DashboardController dashController = Get.find<DashboardController>();
    final BudgetController budgetController = Get.find<BudgetController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // تقليل الحواف
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainMetricCard(context, dashController),
                  const SizedBox(height: 20), // مسافات أقل
                  _buildSectionHeader("Spending Distribution", "By Category Colors"),
                  const SizedBox(height: 12),
                  _buildModernPieChart(context, budgetController),
                  const SizedBox(height: 20),
                  _buildSectionHeader("Detailed Breakdown", "Performance"),
                  const SizedBox(height: 12),
                  _buildEfficiencyList(budgetController),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- المخطط الدائري الملموم ---
  Widget _buildModernPieChart(BuildContext context, BudgetController controller) {
    return Container(
      height: 220, // تصغير الارتفاع من 300
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // زوايا أصغر
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: controller.budgetsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Data Available", style: TextStyle(color: Colors.grey, fontSize: 12)));
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60, // تقليل القطر
                  sections: snapshot.data!.map((budget) {
                    return PieChartSectionData(
                      color: _parseColor(budget['color']),
                      value: (budget['limit_amount'] ?? 1.0).toDouble(),
                      radius: 20, // سمك أنحف
                      showTitle: false,
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("CATEGORIES",
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 8, letterSpacing: 1)),
                  Text("${snapshot.data!.length}",
                      style: const TextStyle(fontWeight: FontWeight.w900, color: deepBlue, fontSize: 20)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  // --- القائمة الملمومة ---
  Widget _buildEfficiencyList(BudgetController controller) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.budgetsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(
          children: snapshot.data!.map((budget) {
            Color catColor = _parseColor(budget['color']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8), // تقليل التباعد بين العناصر
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // تصغير البادينج
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8, // نقاط ملونة أصغر
                    decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget['category_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: deepBlue)),
                        Text("Limit: ${budget['limit_amount']} SAR",
                            style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.black12),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80, // تصغير ارتفاع الهيدر
      pinned: true,
      backgroundColor: deepBlue,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("ANALYTICS",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 15),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildMainMetricCard(BuildContext context, DashboardController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: deepBlue,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: deepBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text("Total Monthly Spent", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Obx(() => Text("${controller.totalExpense.value.toInt()} SAR",
              style: TextStyle(color: Colors.white, fontSize: _res(context, 26), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: deepBlue, fontSize: 14)),
        Text(sub, style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}