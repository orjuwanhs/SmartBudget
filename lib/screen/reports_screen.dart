import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/dashboard_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  final DashboardController dbController = Get.find<DashboardController>(); // ربط الكنترولر ✨

  String _searchKeyword = "";
  String _activeFilterType = "all";
  DateTimeRange? _selectedRange;

  static const Color themeBlue = Color(0xFF103667);
  static const Color themeOrange = Color(0xFFFF6D00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildCompactHeader(),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(_currentUid).collection('transactions')
                  .orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

                final filteredList = _applyFilters(snapshot.data!.docs);
                
                // حساب المجموع بشكل يطابق الداشبورد (غير حساس لحالة الأحرف)
                final totalIn = _calculateTotal(filteredList, 'inc');
                final totalOut = _calculateTotal(filteredList, 'exp');

                return Obx(() {
                  // استخدام الميزانية كـ Income إذا لم يكن هناك فلاتر نشطة
                  double displayIncome = (_activeFilterType == "all" && _selectedRange == null && _searchKeyword.isEmpty)
                      ? dbController.monthlyBudget.value
                      : totalIn;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildCompactDashboard(displayIncome, totalOut)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("HISTORY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black26, letterSpacing: 1.2)),
                            Text("${filteredList.length} Items", style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCompactTransactionTile(filteredList[index].data() as Map<String, dynamic>),
                        childCount: filteredList.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              });
            },
          ),
        ),
      ],
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exportToPdf(),
        backgroundColor: themeBlue,
        elevation: 3,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
        label: const Text("PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  // --- Logic ---
  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final bool typeMatch = _activeFilterType == "all" || data['type'] == _activeFilterType;
      final bool searchMatch = data['category_name'].toString().toLowerCase().contains(_searchKeyword.toLowerCase());
      bool dateMatch = true;
      if (_selectedRange != null) {
        final date = (data['timestamp'] as Timestamp).toDate();
        dateMatch = date.isAfter(_selectedRange!.start) && date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }
      return typeMatch && searchMatch && dateMatch;
    }).toList();
  }

  double _calculateTotal(List<DocumentSnapshot> docs, String typePart) {
    return docs.fold(0.0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String type = (data['type'] ?? "").toString().toLowerCase();
      if (type.contains(typePart.toLowerCase())) {
        return sum + (double.tryParse(data['amount']?.toString() ?? "0") ?? 0.0);
      }
      return sum;
    });
  }

  // --- Compact UI Components ---

  Widget _buildCompactDashboard(double income, double expense) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70, height: 70, // تصغير الشارت
            child: PieChart(PieChartData(sections: [
              PieChartSectionData(value: income == 0 && expense == 0 ? 1 : income, color: Colors.teal, radius: 12, title: ''),
              PieChartSectionData(value: expense, color: themeOrange, radius: 12, title: ''),
            ], sectionsSpace: 2, centerSpaceRadius: 15)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildCompactLegend("Income", income, Colors.teal),
                const SizedBox(height: 6),
                _buildCompactLegend("Expense", expense, themeOrange),
                const Divider(height: 16, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("NET BALANCE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black38)),
                    Text("${(income - expense).toInt()} SAR", style: const TextStyle(fontWeight: FontWeight.w900, color: themeBlue, fontSize: 13)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompactLegend(String title, double val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
        ]),
        Text("${val.toInt()} SAR", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      color: themeBlue,
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 15),
      child: Column(
        children: [
          SizedBox(
            height: 40, // تقليل ارتفاع حقل البحث
            child: TextField(
              onChanged: (val) => setState(() => _searchKeyword = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Search transactions...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                filled: true, fillColor: Colors.white.withOpacity(0.08),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCompactTypeTab("all", "All"),
              _buildCompactTypeTab("income", "In"),
              _buildCompactTypeTab("expense", "Out"),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickDate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(_selectedRange == null ? "Date" : "Filtered",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTypeTab(String type, String label) {
    final bool active = _activeFilterType == type;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: active ? themeBlue : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildCompactTransactionTile(Map<String, dynamic> data) {
    final bool isOut = data['type'] == 'expense';
    final DateTime date = (data['timestamp'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isOut ? Colors.redAccent : Colors.teal, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['category_name'] ?? "General", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text("${isOut ? '-' : '+'}${data['amount']} SAR",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isOut ? Colors.black87 : Colors.teal)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCompactHeader() {
    return AppBar(
      title: const Text("REPORTS", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 13)),
      centerTitle: true, backgroundColor: themeBlue, foregroundColor: Colors.white, elevation: 0, toolbarHeight: 45,
    );
  }

  // --- Handlers ---
  Future<void> _pickDate() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: themeBlue)),
        child: child!,
      ),
    );
    if (range != null) setState(() => _selectedRange = range);
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final snapshot = await _firestore.collection('users').doc(_currentUid).collection('transactions').get();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Financial Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  data: [
                    ['Date', 'Category', 'Type', 'Amount'],
                    ...snapshot.docs.map((e) => [
                      DateFormat('yyyy-MM-dd').format(e['timestamp'].toDate()),
                      e['category_name'],
                      e['type'],
                      "${e['amount']} SAR"
                    ])
                  ]
              )
            ]
        )
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}