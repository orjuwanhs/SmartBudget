/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/dashboard_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // خلفية سوداء عميقة
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("FINANCIAL INSIGHTS",
            style: TextStyle(fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w900, color: Color(0xFF2DD4BF))),
      ),
      body: StreamBuilder<List<PieChartSectionData>>(
        stream: controller.getFilteredCategoryTotals(DateTime.now().subtract(const Duration(days: 30))),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2DD4BF)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyUI();
          }

          final sections = snapshot.data!;
          double totalExpenses = sections.fold(0, (sum, item) => sum + item.value);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // كرت الرسم البياني المركزي
                _buildNeoChart(sections, totalExpenses),
                const SizedBox(height: 40),
                // قائمة البيانات "لكب البيانات" بوضوح
                _buildDataGrid(sections, totalExpenses),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeoChart(List<PieChartSectionData> sections, double total) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.05), blurRadius: 40, spreadRadius: 5),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 90,
              sectionsSpace: 8,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("MONTHLY SPEND", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 5),
              Text("SAR ${total.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDataGrid(List<PieChartSectionData> sections, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CATEGORY BREAKDOWN", style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final sec = sections[index];
            final percent = (sec.value / total) * 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(color: sec.color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: Icon(Icons.tag, color: sec.color, size: 20),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sec.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${percent.toStringAsFixed(1)}% of total", style: const TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("SAR ${sec.value.toStringAsFixed(0)}",
                      style: TextStyle(color: sec.color, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty_rounded, size: 60, color: Colors.white10),
          const SizedBox(height: 20),
          const Text("DATABASE IS EMPTY", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text("Add an 'Expense' to see the magic", style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 12)),
        ],
      ),
    );
  }
}*/