import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/budget_controller.dart';
import '../controllers/category_controller.dart';
import 'analytics_screen.dart';

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  final DashboardController dashController = Get.find<DashboardController>();
  final CategoryController categoryController = Get.isRegistered<CategoryController>()
      ? Get.find<CategoryController>() : Get.put(CategoryController());
  final BudgetController budgetController = Get.isRegistered<BudgetController>()
      ? Get.find<BudgetController>() : Get.put(BudgetController());

  final TextEditingController mainBudgetEditController = TextEditingController();

  static const Color deepBlue = Color(0xFF103667);
  static const Color deepTeal = Color(0xFF00796B);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color appOrange = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    mainBudgetEditController.text = dashController.monthlyBudget.value.toStringAsFixed(0);
  }

  Color _parseColor(dynamic colorData) {
    if (colorData is int) return Color(colorData);
    if (colorData != null) return Color(int.tryParse(colorData.toString()) ?? 0xFF103667);
    return deepBlue;
  }

  IconData _parseIcon(dynamic iconData) {
    int code = (iconData is int) ? iconData : (int.tryParse(iconData?.toString() ?? '') ?? Icons.category.codePoint);
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      // التعديل المطلوب لضمان ثبات الزر تحت وعدم تحركه مع الكيبورد
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: StreamBuilder<double>(
                    stream: dashController.totalExpenseStream,
                    builder: (context, totalSnap) {
                      double totalSpentAll = totalSnap.data ?? 0.0;

                      return Obx(() {
                        double monthlyLimit = dashController.monthlyBudget.value;
                        double overallPercent = monthlyLimit > 0 ? (totalSpentAll / monthlyLimit).clamp(0.0, 1.0) : 0.0;

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            const SizedBox(height: 8),
                            _buildMainVisualCard(totalSpentAll, monthlyLimit, overallPercent),
                            const SizedBox(height: 12),
                            _buildUpdateBudgetCard(),
                            const SizedBox(height: 18),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text("CATEGORIES BUDGETS",
                                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 10, letterSpacing: 1.1)),
                            ),
                            const SizedBox(height: 10),
                            _buildCategoryBudgetsList(),
                            const SizedBox(height: 80),
                          ],
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCategoryBudgetDialog(),
        label: const Text("Set Limit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        icon: const Icon(Icons.add_chart_rounded, size: 18, color: Colors.white),
        backgroundColor: deepBlue,
        elevation: 3,
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Get.back(),
          ),
          const Text("BUDGET MANAGEMENT",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
            onPressed: () => Get.to(() => AnalyticsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: deepBlue, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: deepBlue.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: mainBudgetEditController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: "Limit...", hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.white54, size: 18),
                suffixText: "SAR", suffixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              double newVal = double.tryParse(mainBudgetEditController.text) ?? 0.0;
              if (newVal > 0) {
                await dashController.updateMonthlyBudget(newVal);
                await budgetController.updateMainMonthlyBudget(newVal);
                FocusScope.of(context).unfocus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: deepBlue,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: budgetController.budgetsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        if (snapshot.data!.isEmpty) return _buildEmptyState();

        var list = snapshot.data!.where((b) => b['category_id'] != 'total_all').toList();

        return Column(
          children: list.map((budget) => Dismissible(
            key: Key(budget['id']),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => budgetController.deleteBudget(budget['id']),
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: appOrange.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            ),
            child: _buildCategoryCard(budget),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> budget) {
    String name = budget['category_name'] ?? 'General';
    double limit = (budget['limit_amount'] ?? 0.0).toDouble();
    String categoryId = budget['category_id'] ?? '';
    String budgetType = budget['budget_type'] ?? 'Monthly';

    String expiryStr = "";
    if (budget['expiry_date'] != null) {
      DateTime dt = (budget['expiry_date'] as Timestamp).toDate();
      expiryStr = DateFormat('MMM dd').format(dt);
    }

    return StreamBuilder<double>(
      stream: budgetController.getSpentForCategory(categoryId, limit, name),
      builder: (context, spentSnap) {
        double spent = spentSnap.data ?? 0.0;
        double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
          ),
          child: Row(
            children: [
              Icon(_parseIcon(budget['icon']), color: _parseColor(budget['color']), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: deepBlue)),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: deepBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                              child: Text(budgetType, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: deepBlue)),
                            ),
                          ],
                        ),
                        Text("${(progress * 100).toInt()}%",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: progress >= 0.9 ? appOrange : deepTeal)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: progress >= 0.9 ? appOrange : deepTeal,
                        backgroundColor: Colors.grey.shade100,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${spent.toInt()} / ${limit.toInt()} SAR",
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black38)),
                        if (expiryStr.isNotEmpty)
                          Text("Ends: $expiryStr", style: const TextStyle(fontSize: 8, color: Colors.black26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainVisualCard(double spent, double budget, double percent) {
    bool isExceeded = spent >= budget && budget > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Monthly Spending Progress",
              style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade100,
                        color: isExceeded ? appOrange : deepTeal,
                        strokeCap: StrokeCap.round
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${(percent * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isExceeded ? appOrange : deepBlue
                          )),
                      const Text("Used", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statDetailLarge("Budget", "${budget.toInt()}", deepBlue),
                  const SizedBox(height: 12),
                  _statDetailLarge("Spent", "${spent.toInt()}", isExceeded ? appOrange : Colors.black87),
                  const SizedBox(height: 12),
                  _statDetailLarge("Remains", "${(budget - spent).clamp(0, budget).toInt()}", deepTeal),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDetailLarge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.bold)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 2),
            Text("SAR", style: TextStyle(color: color.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Positioned(top: 0, left: 0, right: 0, height: 140,
        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF103667), Color(0xFF23857B)]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)))));
  }

  Widget _buildEmptyState() {
    return Padding(padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(Icons.account_balance_wallet_outlined, size: 30, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          const Text("No limits set", style: TextStyle(color: Colors.black12, fontSize: 11, fontWeight: FontWeight.bold)),
        ]));
  }

  void _openAddCategoryBudgetDialog() {
    RxnString selectedCatId = RxnString();
    RxnString selectedCatName = RxnString();
    RxString selectedType = 'Monthly'.obs;
    TextEditingController limitController = TextEditingController();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(top: 15, left: 15, right: 15, bottom: Get.context!.mediaQueryViewInsets.bottom + 15),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text("Set Category Limit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: deepBlue)),
              const SizedBox(height: 15),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: categoryController.getCategories(true),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  var categories = snapshot.data!;
                  return Obx(() => DropdownButtonFormField<String>(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                        labelText: "Select Category",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    value: selectedCatId.value,
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat['id'].toString(),
                      child: Row(
                        children: [
                          Icon(_parseIcon(cat['icon']), color: _parseColor(cat['color']), size: 16),
                          const SizedBox(width: 8),
                          Text(cat['name'].toString()),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) {
                      selectedCatId.value = val;
                      var cat = categories.firstWhere((c) => c['id'] == val);
                      selectedCatName.value = cat['name'];
                    },
                  ));
                },
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                value: selectedType.value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: InputDecoration(
                    labelText: "Budget Period",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                ),
                items: ['Weekly', 'Monthly', 'Yearly'].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (val) => selectedType.value = val!,
              )),
              const SizedBox(height: 12),
              TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                      labelText: "Limit Amount (SAR)",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                  )
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  if (selectedCatId.value != null && limitController.text.isNotEmpty) {
                    budgetController.createBudget(
                      categoryId: selectedCatId.value!,
                      categoryName: selectedCatName.value!,
                      limit: double.parse(limitController.text),
                      budgetType: selectedType.value,
                    );
                    Get.back();
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("SAVE BUDGET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}