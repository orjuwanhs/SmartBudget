import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

class CategorySummaryScreen extends StatelessWidget {
  const CategorySummaryScreen({super.key});

  // ميثود مساعدة لتصغير الأحجام بناءً على عرض الشاشة
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    final List<Color> deepColors = [
      const Color(0xFF1A73E8),
      const Color(0xFF00C853),
      const Color(0xFFFF6D00),
      const Color(0xFF9C27B0),
      const Color(0xFFFFD600),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(top: -40, right: -40, child: _buildBlurBlob(Colors.teal.withOpacity(0.08))),
          Positioned(bottom: 80, left: -40, child: _buildBlurBlob(Colors.blueAccent.withOpacity(0.06))),

          SafeArea(
            child: Column(
              children: [
                _buildLightAppBar("Category Summary"),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controller.recentTransactionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      var transactions = snapshot.data!;
                      Map<String, double> categoryTotals = {};
                      Map<String, int> categoryCounts = {};

                      for (var tx in transactions) {
                        String cat = tx['category_name'] ?? tx['categoryName'] ?? 'Other';
                        double amt = double.tryParse(tx['amount']?.toString() ?? '0.0') ?? 0.0;
                        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
                        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
                      }

                      double totalSum = categoryTotals.values.fold(0, (sum, item) => sum + item);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // تقليل الحواف
                        child: Column(
                          children: [
                            _buildDeepChartCard(context, categoryTotals, totalSum, deepColors),
                            const SizedBox(height: 15), // مسافة أقل
                            _buildDeepSummaryList(categoryTotals, categoryCounts, deepColors),
                          ],
                        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          const Text("No transactions found", style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(Color color) => Container(
      width: 250, height: 250, // تصغير حجم الـ Blur
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]
      )
  );

  Widget _buildLightAppBar(String title) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Get.back(),
        ),
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    ),
  );

  Widget _buildDeepChartCard(BuildContext context, Map<String, double> totals, double totalSum, List<Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // تقليل البادينج
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Analysis", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900)),
              Text("${DateTime.now().month}/${DateTime.now().year}", style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 160, // تصغير الارتفاع من 200
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 60, // تقليل القطر
                    sections: _generateDeepSections(totals, colors),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Total", style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("${totalSum.toStringAsFixed(0)}",
                          style: TextStyle(color: Colors.black, fontSize: _res(context, 22), fontWeight: FontWeight.w900)),
                      const Text("SAR", style: TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: totals.keys.toList().asMap().entries.map((entry) {
              int idx = entry.key;
              String name = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8, // تصغير النقاط
                    decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(name, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepSummaryList(Map<String, double> totals, Map<String, int> counts, List<Color> colors) {
    List<String> categories = totals.keys.toList();
    return Column(
      children: categories.asMap().entries.map((entry) {
        int idx = entry.key;
        String name = entry.value;
        return _deepSummaryTile(
            name,
            "${counts[name]} Txns", // اختصار لكلمة Transactions لملاءمة الحجم
            totals[name]!.toStringAsFixed(1),
            colors[idx % colors.length],
            _getCategoryIcon(name)
        );
      }).toList(),
    );
  }

  Widget _deepSummaryTile(String title, String subtitle, String amount, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ملموم أكثر
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), // تصغير البادينج للأيقونة
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text("$amount", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(width: 4),
          const Text("SAR", style: TextStyle(color: Colors.black26, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateDeepSections(Map<String, double> totals, List<Color> colors) {
    int i = 0;
    return totals.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 16, // سمك الحلقة أنحف
      );
    }).toList();
  }

  IconData _getCategoryIcon(String name) {
    String n = name.toLowerCase();
    if (n.contains('food')) return Icons.restaurant_rounded;
    if (n.contains('shop')) return Icons.local_mall_rounded;
    if (n.contains('trans')) return Icons.directions_car_rounded;
    if (n.contains('health')) return Icons.medical_services_rounded;
    if (n.contains('home')) return Icons.home_rounded;
    if (n.contains('trip')) return Icons.flight_takeoff_rounded;
    return Icons.category_rounded;
  }
}