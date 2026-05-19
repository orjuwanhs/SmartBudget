import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../controllers/dashboard_controller.dart';

class FinanceOverviewScreen extends StatelessWidget {
  const FinanceOverviewScreen({super.key});

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color textBlack = Color(0xFF000000);
  static const Color bgLight = Color(0xFFF8FAFC);

  // ميثود متجاوبة لتصغير الأحجام
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(
              top: -60,
              right: -60,
              child: _buildBlurBlob([deepTeal.withOpacity(0.1), Colors.teal.shade900.withOpacity(0.06)])
          ),
          Positioned(
              bottom: 80,
              left: -70,
              child: _buildBlurBlob([deepBlue.withOpacity(0.08), Colors.blue.shade900.withOpacity(0.04)])
          ),

          SafeArea(
            child: AnimationLimiter(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 500),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 30.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            const SizedBox(height: 10),
                            Obx(() {
                              double budget = controller.monthlyBudget.value;
                              double spent = controller.totalExpense.value;
                              return _buildMainBalanceCard(
                                context,
                                balance: budget - spent,
                                income: budget,
                              );
                            }),
                            const SizedBox(height: 20),
                            _buildDateHeader(),
                            Obx(() => _buildChartSection(controller.dailyCashFlowPoints)),
                            const SizedBox(height: 12),
                            _buildTimeFilter(controller),
                            const SizedBox(height: 20),
                            Obx(() => _buildCashFlowCard(
                              income: controller.monthlyBudget.value,
                              expense: controller.totalExpense.value,
                            )),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 280, height: 280, // تصغير حجم البلور
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 100, spreadRadius: 50)]
      )
  );

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      toolbarHeight: 50,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
        onPressed: () => Get.back(),
      ),
      title: const Text("Overview", style: TextStyle(color: textBlack, fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, {required double balance, required double income}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: deepBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${balance.toStringAsFixed(1)} \$", style: TextStyle(color: Colors.white, fontSize: _res(context, 24), fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                child: Text("+${income.toInt()}\$", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Monthly Analysis", style: TextStyle(color: textBlack, fontSize: 15, fontWeight: FontWeight.w900)),
        Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChartSection(List<FlSpot> spots) {
    return Container(
      height: 160, // تصغير الارتفاع من 220
      margin: const EdgeInsets.only(top: 15),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold);
                  // Dynamic labels based on period could be added here
                  return Text(value.toInt().toString(), style: style);
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: deepBlue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [deepBlue.withOpacity(0.15), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(DashboardController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["Week", "Month", "Year"].map((e) {
        return Obx(() {
          bool active = controller.selectedPeriod.value == e;
          return GestureDetector(
            onTap: () => controller.changePagePeriod(e),
            child: _filterBtn(e, active),
          );
        });
      }).toList(),
    );
  }

  Widget _filterBtn(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: active ? deepBlue : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: active ? Colors.transparent : Colors.black.withOpacity(0.05)),
      ),
      child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildCashFlowCard({required double income, required double expense}) {
    return Container(
      padding: const EdgeInsets.all(20), // تقليل البادينج
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cash Flow", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              Text("${(income - expense).toStringAsFixed(1)}\$", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: deepBlue)),
            ],
          ),
          const SizedBox(height: 15),
          _flowItem(Icons.arrow_upward, "Income", "${income.toInt()}\$", Colors.green),
          const SizedBox(height: 10),
          _flowItem(Icons.arrow_downward, "Expenses", "${expense.toInt()}\$", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _flowItem(IconData icon, String title, String amount, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
        const Spacer(),
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
  }
}