import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/ai_controller.dart';
import '../controllers/dashboard_controller.dart';

class AnalyticsScreen extends StatelessWidget {
  AnalyticsScreen({super.key});

  final AIController aiController = Get.find<AIController>();
  final DashboardController dbController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    // Trigger AI analysis only if not already started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dbController.expenseDistribution.isNotEmpty && !aiController.isAnalysisStarted.value) {
        aiController.analyzeCategorySpending(dbController.expenseDistribution);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("FINANCIAL INSIGHTS", 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF1E3A8A))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: FUNCTION-DRIVEN BUDGET COMPARISON ---
            _buildSectionHeader("BUDGET COMPLIANCE", Icons.account_balance_wallet_rounded),
            const SizedBox(height: 15),
            _buildBudgetComplianceCard(),
            const SizedBox(height: 25),
            _buildSectionHeader("CASH FLOW TREND", Icons.trending_up_rounded),
            const SizedBox(height: 15),
            _buildLineChartCard(),

            const SizedBox(height: 35),

            // --- SECTION 2: AI-DRIVEN CATEGORY ANALYSIS (PIE CHART) ---
            _buildSectionHeader("AI CATEGORY SCAN", Icons.auto_awesome),
            const SizedBox(height: 15),
            _buildAIAdviceCard(),
            const SizedBox(height: 20),
            _buildPieChartCard(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E3A8A).withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: const Color(0xFF1E3A8A).withOpacity(0.7), letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildBudgetComplianceCard() {
    return Obx(() {
      double spent = dbController.totalExpense.value;
      double budget = dbController.monthlyBudget.value;
      double percent = budget > 0 ? (spent / budget) : 0;
      double remaining = budget - spent;
      if (percent > 1.0) percent = 1.0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(25), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Monthly Spending Status", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("${spent.toInt()} / ${budget.toInt()} SAR", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text(remaining >= 0 ? "${remaining.toInt()} SAR Remaining" : "Over Budget!", 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.green : Colors.red)),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.blueGrey.withOpacity(0.05),
                    color: percent > 0.9 ? Colors.red : (percent > 0.7 ? Colors.orange : Colors.green),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Obx(() {
              final spots = dbController.dailyCashFlowPoints;
              if (dbController.allTransactions.isEmpty) return const Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey, fontSize: 11)));
              return LineChart(_lineChartData(spots));
            }),
          ),
          const SizedBox(height: 15),
          _buildPeriodToggle(),
        ],
      ),
    );
  }

  Widget _buildAIAdviceCard() {
    return Obx(() {
      bool isLoading = aiController.isLoading.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                const Text("AI CATEGORY ADVISOR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF1E3A8A), letterSpacing: 1.2)),
                const Spacer(),
                if (isLoading) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              aiController.categoryAdvice.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Obx(() {
              final data = dbController.expenseDistribution;
              if (data.isEmpty) return const Center(child: Text("No expenses to analyze", style: TextStyle(color: Colors.grey, fontSize: 11)));
              return PieChart(_pieChartData(data));
            }),
          ),
          const SizedBox(height: 20),
          _buildPieLegend(),
        ],
      ),
    );
  }

  Widget _buildPieLegend() {
    return Obx(() {
      final data = dbController.expenseDistribution;
      return Wrap(
        spacing: 12, runSpacing: 8,
        children: data.asMap().entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.primaries[entry.key % Colors.primaries.length], shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(entry.value['categoryName'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildPeriodToggle() {
    List<String> periods = ['Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          return Obx(() {
            bool isSelected = dbController.selectedPeriod.value == period;
            return GestureDetector(
              onTap: () => dbController.changePagePeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text(period, style: TextStyle(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  LineChartData _lineChartData(List<FlSpot> spots) => LineChartData(
    gridData: const FlGridData(show: false),
    titlesData: const FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
    lineBarsData: [
      LineChartBarData(
        spots: spots, 
        isCurved: true, 
        color: const Color(0xFF10B981), 
        barWidth: 4, 
        dotData: const FlDotData(show: true), 
        belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.05))
      )
    ]
  );

  PieChartData _pieChartData(List<Map<String, dynamic>> data) => PieChartData(
    centerSpaceRadius: 50,
    sectionsSpace: 4,
    sections: data.asMap().entries.map((entry) => PieChartSectionData(
      color: Colors.primaries[entry.key % Colors.primaries.length],
      value: entry.value['amount'].toDouble(),
      title: '',
      radius: 20,
    )).toList()
  );
}
