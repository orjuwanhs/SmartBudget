import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/dashboard_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'EditTransactionPage.dart';
import 'package:flutter/services.dart';

class MainBalanceCard extends StatefulWidget {
  const MainBalanceCard({super.key});

  @override
  State<MainBalanceCard> createState() => _MainBalanceCardState();
}

class _MainBalanceCardState extends State<MainBalanceCard> {
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController searchController = TextEditingController();

  RxString filterType = 'All'.obs;
  Rx<DateTimeRange?> dateRange = Rx<DateTimeRange?>(null);

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color deepGreen = Color(0xFF00C853);
  static const Color deepOrange = Color(0xFFFF6D00);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF000000);

  // ميثود متجاوبة لتصغير الأحجام
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _buildBlurBlob([deepTeal.withOpacity(0.08), Colors.teal.withOpacity(0.04)])),
          Positioned(bottom: 120, left: -70, child: _buildBlurBlob([deepBlue.withOpacity(0.06), Colors.blue.withOpacity(0.04)])),

          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Column(
                    children: [
                      _buildModernSearchBar(),
                      const SizedBox(height: 12),
                      _buildModernFilterRow(),
                      _buildSelectedDateRangeChip(),
                    ],
                  ),
                ),

                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      _buildAnimatedList(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomSummary(context)),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 300, height: 300,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors))
  );

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
            onPressed: () => Get.back(),
          ),
          const Text("TRANSACTIONS",
              style: TextStyle(color: textBlack, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: deepTeal, size: 18),
            onPressed: () => _pickDateRange(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateRangeChip() {
    return Obx(() {
      if (dateRange.value == null) return const SizedBox.shrink();
      String rangeText = "${DateFormat('MMM dd').format(dateRange.value!.start)} - ${DateFormat('MMM dd').format(dateRange.value!.end)}";
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 28,
          child: Chip(
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: deepTeal.withOpacity(0.08),
            label: Text(rangeText, style: const TextStyle(color: deepTeal, fontSize: 10, fontWeight: FontWeight.bold)),
            deleteIcon: const Icon(Icons.close, size: 12, color: deepTeal),
            onDeleted: () => dateRange.value = null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    });
  }

  Widget _buildModernSearchBar() {
    return Container(
      height: 40, // تقليل الارتفاع من 50
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (v) => setState(() {}),
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: "Search categories...",
          hintStyle: TextStyle(color: Colors.black26, fontSize: 12),
          icon: Icon(Icons.search_rounded, color: deepTeal, size: 18),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildModernFilterRow() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['All', 'Income', 'Expense'].map((type) {
        bool active = filterType.value == type;
        Color activeColor = type == 'Income' ? deepGreen : (type == 'Expense' ? deepOrange : deepBlue);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            filterType.value = type;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // تقليل البادينج
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active ? [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Text(
              type,
              style: TextStyle(color: active ? Colors.white : Colors.black38, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildTransactionItem(Map<String, dynamic> data, int index, BuildContext context) {
    // 1. استخراج النوع والمبالغ (تحويل آمن لـ double لتجنب Null)
    final String type = (data['type'] ?? "expense").toString().toLowerCase();
    final bool isIncome = type == 'income';
    final double amount = (data['amount'] ?? 0).toDouble();

    // 2. إصلاح مسميات المفاتيح (Keys) لتطابق بياناتك (category_color بدلاً من categoryColor)
    final Color c = _parseColor(data['category_color'] ?? data['categoryColor']);
    final IconData displayIcon = _parseIcon(data['category_icon'] ?? data['categoryIcon']);

    // 3. معالجة التاريخ والاسم
    final String catName = (data['category_name'] ?? data['categoryName'] ?? "General").toString();
    final DateTime date = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: FadeInAnimation(
        child: Dismissible(
          key: Key(data['id']?.toString() ?? index.toString()),
          background: _buildDismissBackground(Colors.blueAccent, Icons.edit_rounded, Alignment.centerLeft),
          secondaryBackground: _buildDismissBackground(Colors.redAccent, Icons.delete_forever_rounded, Alignment.centerRight),
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              HapticFeedback.vibrate();
              controller.deleteTransaction(data['id']);
            }
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              HapticFeedback.mediumImpact();
              Get.to(() => EditTransactionPage(data: data));
              return false;
            }
            return true;
          },
          child: InkWell(
            onTap: () => _showTransactionDetails(context, data),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 5)]
              ),
              child: Row(
                children: [
                  // أيقونة الفئة الملونة (تأكد من استخدام displayIcon)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Icon(displayIcon, color: c, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // الاسم والتاريخ (باستخدام المسميات الصحيحة)
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              catName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF103667))
                          ),
                          Text(
                              DateFormat('dd MMM, hh:mm a').format(date),
                              style: const TextStyle(color: Colors.black26, fontSize: 9)
                          ),
                        ]
                    ),
                  ),

                  // زر التعديل
                  IconButton(
                    icon: Icon(Icons.edit_note_rounded, color: Colors.black.withOpacity(0.1), size: 22),
                    onPressed: () => Get.to(() => EditTransactionPage(data: data)),
                  ),

                  // المبلغ والعملة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          "${isIncome ? '+' : '-'}$amount",
                          style: TextStyle(
                              color: isIncome ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
                              fontWeight: FontWeight.w900,
                              fontSize: 14
                          )
                      ),
                      const Text(
                          "SAR",
                          style: TextStyle(color: Colors.black26, fontSize: 8, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // تعديل ميثود القائمة لتشمل خاصية الضغط لعرض التفاصيل
  Widget _buildAnimatedList() {
    return Obx(() {
      // 1. حالة التحميل
      if (controller.isTransactionsLoading.value) {
        return const SliverToBoxAdapter(
          child: Center(child: Padding(
            padding: EdgeInsets.all(50.0),
            child: CircularProgressIndicator(strokeWidth: 2, color: deepTeal),
          )),
        );
      }

      // 2. الفلترة المحلية (Client-side filtering)
      var filtered = controller.allTransactions.where((tx) {
        String typeDb = (tx['type'] ?? "").toString().toLowerCase();
        bool matchType = filterType.value == 'All' || typeDb == filterType.value.toLowerCase();
        bool matchText = (tx['categoryName'] ?? "").toString().toLowerCase().contains(searchController.text.toLowerCase());

        DateTime txDate = tx['timestamp'] is Timestamp ? (tx['timestamp'] as Timestamp).toDate() : DateTime.now();
        bool matchDate = true;
        if (dateRange.value != null) {
          DateTime start = DateTime(dateRange.value!.start.year, dateRange.value!.start.month, dateRange.value!.start.day);
          DateTime end = DateTime(dateRange.value!.end.year, dateRange.value!.end.month, dateRange.value!.end.day, 23, 59);
          matchDate = txDate.isAfter(start) && txDate.isBefore(end);
        }
        return matchType && matchText && matchDate;
      }).toList();

      // 3. حالة لا توجد بيانات
      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 60, color: deepBlue.withOpacity(0.05)),
                const SizedBox(height: 10),
                const Text("NO TRANSACTIONS YET",
                    style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }

      // 4. عرض القائمة المتحركة
      return AnimationLimiter(
        child: SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final data = filtered[index];
              // ... بقية الكود الخاص بـ Dismissible و Container القائمة كما هو عندك
              return _buildTransactionItem(data, index, context);// يفضل فصله في ميثود
            }, childCount: filtered.length),
          ),
        ),
      );
    });
  }

  // ميثود عرض تفاصيل العملية بنفس الستايل الجذاب
  void _showTransactionDetails(BuildContext context, Map<String, dynamic> data) {
    // 1. استخراج الألوان والأيقونات مع دعم المسميات الجديدة والقديمة (Safety First)
    final Color c = _parseColor(data['category_color'] ?? data['categoryColor']);
    final IconData displayIcon = _parseIcon(data['category_icon'] ?? data['categoryIcon']);

    // 2. معالجة النصوص والمبالغ لتجنب خطأ Null
    final String catName = (data['category_name'] ?? data['categoryName'] ?? "General").toString();
    final String type = (data['type'] ?? "expense").toString().toLowerCase();
    final String note = (data['note'] ?? "").toString();
    final String amount = (data['amount'] ?? "0").toString();

    final bool isInc = type == 'income';
    final DateTime date = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
              ),
              const SizedBox(height: 20),

              // أيقونة الفئة الملونة
              Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      shape: BoxShape.circle
                  ),
                  child: Icon(displayIcon, color: c, size: 40)
              ),

              const SizedBox(height: 12),
              Text(catName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF103667))),
              Text(
                  "${isInc ? '+' : '-'}$amount SAR",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isInc ? const Color(0xFF00C853) : const Color(0xFFFF6D00)
                  )
              ),
              const SizedBox(height: 25),

              // صندوق التفاصيل المحسن
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05))
                ),
                child: Column(
                  children: [
                    _detailRow("Transaction Type", isInc ? "Income" : "Expense", isInc ? Colors.green : Colors.redAccent),
                    const Divider(height: 30),
                    _detailRow("Date & Time", DateFormat('dd MMM yyyy, hh:mm a').format(date), Colors.black54),
                    const Divider(height: 30),

                    // قسم الملاحظات
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.notes_rounded, size: 14, color: Colors.black26),
                          SizedBox(width: 5),
                          Text("NOTES", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            note.isEmpty ? "No additional notes." : note,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0
                    ),
                    child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2))
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
  Widget _detailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildDismissBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  /*Widget _buildBottomSummary(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25), // تقليل الارتفاع
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border(top: BorderSide(color: Colors.black.withOpacity(0.03)))),
          child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: controller.recentTransactionsStream,
              builder: (context, snapshot) {
                double income = 0;
                double expense = 0;
                if (snapshot.hasData) {
                  for (var tx in snapshot.data!) {
                    double amt = (tx['amount'] as num).toDouble();
                    if (tx['type'].toString().toLowerCase() == 'income') {
                      income += amt;
                    } else {
                      expense += amt;
                    }
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _modernSumItem("INCOME", income, deepGreen),
                    _modernSumItem("EXPENSE", expense, deepOrange),
                    _modernSumItem("NET", income - expense, deepBlue),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }*/

  Widget _buildBottomSummary(BuildContext context) {
    return Obx(() {
      double income = 0;
      double expense = 0;

      // نستخدم القائمة الموحدة في الكنترولر لمنع التكرار
      for (var tx in controller.allTransactions) {
        double amt = (tx['amount'] as num).toDouble();
        if (tx['type'].toString().toLowerCase() == 'income') {
          income += amt;
        } else {
          expense += amt;
        }
      }

      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border(top: BorderSide(color: Colors.black.withOpacity(0.03)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _modernSumItem("INCOME", income, deepGreen),
                _modernSumItem("EXPENSE", expense, deepOrange),
                _modernSumItem("NET", income - expense, deepBlue),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _modernSumItem(String label, double val, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.black26, fontSize: 9, fontWeight: FontWeight.w900)),
      // تغيير العلامة هنا
      Text("${val.toInt()} SAR", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
    ]);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: deepTeal, onPrimary: Colors.white, surface: Colors.white, onSurface: textBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) dateRange.value = picked;
  }

  Color _parseColor(dynamic colorData) {
    if (colorData == null) return deepBlue;
    try {
      if (colorData is int) return Color(colorData);
      String colorStr = colorData.toString();
      if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr.substring(2), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorStr));
    } catch (e) {
      return deepBlue;
    }
  }

  IconData _parseIcon(dynamic iconData) {
    if (iconData == null) return Icons.category;
    try {
      if (iconData is int) return IconData(iconData, fontFamily: 'MaterialIcons');
      int? code = int.tryParse(iconData.toString());
      if (code != null) return IconData(code, fontFamily: 'MaterialIcons');
      
      // Fallback for common icon names if they are stored as strings
      switch (iconData.toString()) {
        case 'medical_services': return Icons.medical_services;
        case 'shopping_cart': return Icons.shopping_cart;
        case 'restaurant': return Icons.restaurant;
        case 'directions_car': return Icons.directions_car;
        default: return Icons.category;
      }
    } catch (e) {
      return Icons.category;
    }
  }
}