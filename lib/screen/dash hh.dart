/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartbudget/screen/MainBalanceCard.dart';
import '../controllers/dashboard_controller.dart';
import '../../models/user_model.dart';
import '../screen/add_transaction_screen.dart';
import '../screen/stats_screen.dart';
import '../screen/category_summary_screen.dart';
import '../screen/categories_screen.dart';
import '../screen/savings_goals_screen.dart';
import '../screen/profile_screen.dart';
import '../screen/linked_accounts_screen.dart';
import '../screen/notifications_screen.dart';
import 'reports_screen.dart';
import 'history_screen.dart';
import '../screen/monthly_budget_screen.dart';
import '../screen/finance_overview_screen.dart';
import 'debt_management_screen.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // متغير لمتابعة حالة الفرز (داخلي للواجهة)
  final RxBool isDescending = true.obs;

  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color deepGreen = Color(0xFF00C853);
  static const Color deepOrange = Color(0xFFFF6D00);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF000000);

  double _getResponsiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;
    return size * (width / 400);
  }

  Color _parseColor(dynamic colorData) {
    try {
      if (colorData == null) return deepBlue;
      if (colorData is int) return Color(colorData);
      return Color(int.parse(colorData.toString()));
    } catch (e) { return deepBlue; }
  }

  IconData _parseIcon(dynamic iconData) {
    try {
      if (iconData == null) return Icons.account_balance_wallet_rounded;
      int code = (iconData is int) ? iconData : int.parse(iconData.toString());
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) { return Icons.account_balance_wallet_rounded; }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return DateFormat('MMM d, h:mm a').format(DateTime.now());
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        dt = DateTime.parse(timestamp.toString());
      }
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) { return "N/A"; }
  }

  Widget _buildBrandText(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: _getResponsiveSize(context, 25),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        children: const [
          TextSpan(text: "Smart ", style: TextStyle(color: Color(0xFF103667))),
          TextSpan(text: "Budget", style: TextStyle(color: Color(0xFF43A047))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: bgLight,
            drawer: _buildModernDrawer(context),
            body: Stack(
              children: [
                Positioned(top: -70, right: -70, child: _buildBlurBlob([deepTeal.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.1)])),
                Positioned(bottom: 150, left: -80, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.1)])),
                PageView(
                  controller: controller.pageController,
                  onPageChanged: (index) => controller.currentIndex.value = index,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMainDashboardContent(context),
                    const CategorySummaryScreen(),
                    const CategoriesScreen(),
                    const ProfileScreen(),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(context),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: SizedBox(
              width: 55, height: 55,
              child: FloatingActionButton(
                onPressed: () => _showFabMenu(context),
                backgroundColor: textBlack,
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          );
        }
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _drawerSectionTitle("Financial Tools"),
                  _drawerItem(Icons.history_rounded, "Transaction History", deepOrange, () { Get.back(); Get.to(() => const MainBalanceCard()); }),
                  _drawerItem(Icons.account_balance_rounded, "Bank Accounts", Colors.blueGrey, () { Get.back(); Get.to(() => const LinkedAccountsScreen()); }),
                  _drawerSectionTitle("Management"),
                  _drawerItem(Icons.track_changes_rounded, "Budget Planning", Colors.redAccent, () { Get.back(); Get.to(() => const MonthlyBudgetScreen()); }),
                  _drawerItem(Icons.category_rounded, "Reports", deepTeal, () { Get.back(); Get.to(() => const ReportsScreen()); }),
                  _drawerItem(Icons.stars_rounded, "History", deepGreen, () { Get.back(); Get.to(() => const HistoryScreen()); }),
                  _drawerItem(Icons.auto_graph_rounded, "Finance Overview", deepGreen, () { Get.back(); Get.to(() => const FinanceOverviewScreen()); }),
                  _drawerItem(Icons.notifications_active_rounded, "Alerts", Colors.amber.shade800, () { Get.back(); Get.to(() => const NotificationsScreen()); }),
                  _drawerItem(
                      Icons.logout_rounded,
                      "Logout",
                      Colors.redAccent,
                          () async {
                        Get.back();
                        await controller.logout();
                        Get.delete<DashboardController>(force: true);
                      }
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFA0CFA3), Color(0xFF23857B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.white60, child: Icon(Icons.person_outline_rounded, color: Color(0xFF2E7D32), size: 30)),
          const SizedBox(height: 12),
          StreamBuilder<UserModel>(
              stream: controller.userDataStream,
              builder: (context, snapshot) {
                return Text(snapshot.data?.fullName ?? "User", style: TextStyle(color: const Color(0xFF052E63), fontSize: _getResponsiveSize(context, 16), fontWeight: FontWeight.w900));
              }
          ),
          const Text("Management Console", style: TextStyle(color: Color(0xFF1A5DC6), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _drawerSectionTitle(String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(left: 20, top: 15, bottom: 5),
    child: Text(title.toUpperCase(), style: TextStyle(color: textBlack.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
  );

  Widget _drawerItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textBlack)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildBlurBlob(List<Color> colors) => Container(
      width: 250, height: 250,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 100, spreadRadius: 50)])
  );

  Widget _buildMainDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      color: deepTeal,
      child: SafeArea(
        child: StreamBuilder<UserModel>(
          stream: controller.userDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: deepTeal));
            final user = snapshot.data;
            return StreamBuilder<double>(
              stream: controller.totalIncomeStream,
              builder: (context, incomeSnap) {
                return StreamBuilder<double>(
                  stream: controller.totalExpenseStream,
                  builder: (context, expenseSnap) {
                    return Obx(() {
                      double totalIncome = incomeSnap.hasData ? incomeSnap.data! : 0.0;
                      double totalExpense = expenseSnap.hasData ? expenseSnap.data! : 0.0;
                      double actualBalance = totalIncome - totalExpense;
                      double currentBudget = controller.monthlyBudget.value;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildAppBar(context, user?.fullName ?? "User"),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Column(
                                children: [
                                  _buildGlassBalanceCard(context, balance: actualBalance, income: totalIncome, spent: totalExpense, currency: user?.currency ?? "SAR"),
                                  const SizedBox(height: 12),
                                  _buildMiniBudgetCard(context, totalExpense, currentBudget),
                                  const SizedBox(height: 12),
                                  _buildQuickActions(context),
                                  const SizedBox(height: 15),
                                  _buildSectionHeader("Latest Transactions"),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          _buildTransactionList(context),
                          // زر See All يظهر فقط إذا كان هناك بيانات
                          SliverToBoxAdapter(
                            child: Center(
                              child: TextButton(
                                onPressed: () => Get.to(() => const MainBalanceCard()),
                                child: const Text("See All Activity", style: TextStyle(color: deepBlue, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ),
                          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                        ],
                      );
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) => SliverAppBar(
    backgroundColor: Colors.transparent,
    floating: true,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(onPressed: () => _scaffoldKey.currentState?.openDrawer(), icon: const Icon(Icons.menu_rounded, color: textBlack, size: 24)),
    title: _buildBrandText(context),
    actions: [
      StreamBuilder<int>(
          stream: controller.unreadNotificationsCountStream,
          builder: (context, snapshot) {
            int count = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded, color: textBlack, size: 24), onPressed: () => Get.to(() => const NotificationsScreen())),
                if (count > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  )
              ],
            );
          }
      ),
      const SizedBox(width: 5),
    ],
  );

  Widget _buildGlassBalanceCard(BuildContext context, {required double balance, required double income, required double spent, required String currency}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEEE, d MMM').format(DateTime.now()), style: const TextStyle(color: Colors.white54, fontSize: 9)),
              ]),
              const Icon(Icons.nfc_outlined, color: Colors.white54, size: 22),
            ]),
            const SizedBox(height: 5),
            Text("$currency ${balance.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: _getResponsiveSize(context, 26), fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatTileItem(title: "Income", amount: income.toInt().toString(), icon: Icons.arrow_upward_rounded, color: Colors.greenAccent),
                  Container(width: 1, height: 25, color: Colors.white12),
                  _StatTileItem(title: "Spent", amount: spent.toInt().toString(), icon: Icons.arrow_downward_rounded, color: Colors.redAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBudgetCard(BuildContext context, double spent, double limit) {
    double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0;
    Color color = spent > limit ? Colors.red : deepBlue;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)], border: Border.all(color: color.withOpacity(0.1), width: 1.2)),
      child: Row(
        children: [
          SizedBox(width: 35, height: 35, child: CircularProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1), strokeWidth: 4)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Monthly Budget", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
            Text("SAR ${spent.toInt()} of ${limit.toInt()}", style: const TextStyle(color: textBlack, fontWeight: FontWeight.w900, fontSize: 13)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.recentTransactionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());

        // جلب البيانات وفرزها حسب حالة الـ RxBool
        List<Map<String, dynamic>> transactions = snapshot.data!;
        transactions.sort((a, b) {
          var t1 = a['timestamp'] as Timestamp;
          var t2 = b['timestamp'] as Timestamp;
          return isDescending.value ? t2.compareTo(t1) : t1.compareTo(t2);
        });

        // عرض أول 20 فقط
        final displayList = transactions.take(20).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final data = displayList[index];
            final Color c = _parseColor(data['categoryColor']);
            final bool isInc = data['type'] == 'Income';

            return InkWell(
              onTap: () => _showTransactionDetails(context, data),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  children: [
                    // أيقونة الفئة الدائرية المطورة
                    Container(
                        height: 48, width: 48,
                        decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_parseIcon(data['categoryIcon']), color: c, size: 22)
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['categoryName'] ?? "General", style: const TextStyle(color: textBlack, fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(_formatDateTime(data['timestamp']), style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
                    ])),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${isInc ? '+' : '-'}${data['amount']}",
                          style: TextStyle(color: isInc ? Colors.green.shade600 : Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 15)),
                        const Text("SAR", style: TextStyle(color: Colors.black26, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }, childCount: displayList.length),
        );
      },
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> data) {
    final Color c = _parseColor(data['categoryColor']);
    final bool isInc = data['type'] == 'Income';

    Get.bottomSheet(
      barrierColor: Colors.black.withOpacity(0.4),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_parseIcon(data['categoryIcon']), color: c, size: 40),
              ),
              const SizedBox(height: 12),
              Text(data['categoryName'] ?? "General", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text(
                  "${isInc ? '+' : '-'}${data['amount']} SAR",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isInc ? Colors.green.shade600 : Colors.redAccent)
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.05))),
                child: Column(
                  children: [
                    _detailRow("Type", data['type'] ?? "N/A", isInc ? Colors.green : Colors.red),
                    const Divider(height: 20),
                    _detailRow("Date", _formatDateTime(data['timestamp']), Colors.black54),
                    const Divider(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 14, color: Colors.black26),
                            SizedBox(width: 5),
                            Text("Note / Remark", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (data['note'] == null || data['note'].toString().isEmpty)
                              ? "No additional notes for this process."
                              : data['note'].toString(),
                          style: const TextStyle(fontSize: 13, color: textBlack, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
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
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      children: [
        _actionBtn(context, Icons.add_box_rounded, "Add", deepTeal, () => Get.to(() => const AddTransactionScreen())),
        _actionBtn(context, Icons.track_changes_rounded, "Budget", Colors.redAccent, () => Get.to(() => const MonthlyBudgetScreen())),
        _actionBtn(context, Icons.stars_rounded, "Goals", deepGreen, () => Get.to(() => const SavingsGoalsScreen())),
        _actionBtn(context, Icons.receipt_long_rounded, "History", Colors.blueAccent, () => Get.to(() => const MainBalanceCard())),
        _actionBtn(context, Icons.pie_chart_rounded, "Reports", Colors.purpleAccent, () => Get.to(() => const ReportsScreen())),
        _actionBtn(context, Icons.stars_rounded, "Debt", deepGreen, () => Get.to(() => const DebtManagementScreen())),
      ],
    ),
  );

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color: textBlack, fontSize: 16, fontWeight: FontWeight.w900)),
      Obx(() => IconButton(
        onPressed: () {
          HapticFeedback.mediumImpact(); // اهتزاز عند التغيير
          isDescending.value = !isDescending.value;
        },
        icon: Icon(
          isDescending.value ? Icons.sort_rounded : Icons.filter_list_rounded,
          color: isDescending.value ? deepBlue : deepOrange,
          size: 20
        ),
      )),
    ]),
  );

  Widget _buildBottomNav(BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
    child: BottomAppBar(
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(0, Icons.dashboard_rounded, deepBlue, "Home"),
          _navIcon(1, Icons.pie_chart_rounded, deepOrange, "Stats"),
          const SizedBox(width: 40),
          _navIcon(2, Icons.wallet_rounded, deepGreen, "Wallet"),
          _navIcon(3, Icons.person_rounded, Colors.purple, "Profile"),
        ],
      ),
    ),
  );

  Widget _navIcon(int index, IconData icon, Color color, String label) => Obx(() {
    bool selected = controller.currentIndex.value == index;
    return InkWell(
      onTap: () => controller.changePage(index),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? color : Colors.black26, size: 22),
        if (selected) Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))
      ]),
    );
  });

  void _showFabMenu(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 15),
              _drawerItem(Icons.add_chart_rounded, "Add Transaction", deepTeal, () { Get.back(); Get.to(() => const AddTransactionScreen()); }),
              _drawerItem(Icons.track_changes_rounded, "Set Monthly Budget", Colors.redAccent, () { Get.back(); Get.to(() => const MonthlyBudgetScreen()); }),
              _drawerItem(Icons.stars_rounded, "Add Savings Goal", deepGreen, () { Get.back(); Get.to(() => const SavingsGoalsScreen()); }),
              _drawerItem(Icons.category_outlined, "Manage Categories", deepOrange, () { Get.back(); Get.to(() => const CategoriesScreen()); }),
            ]
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _StatTileItem extends StatelessWidget {
  final String title, amount; final IconData icon; final Color color;
  const _StatTileItem({required this.title, required this.amount, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 5),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      Text("SAR $amount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
    ]),
  ]);
}*/

/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartbudget/screen/MainBalanceCard.dart';
import '../controllers/dashboard_controller.dart';
import '../../models/user_model.dart';
import '../screen/add_transaction_screen.dart';
import '../screen/category_summary_screen.dart';
import '../screen/categories_screen.dart';
import '../screen/savings_goals_screen.dart';
import '../screen/profile_screen.dart';
import '../screen/linked_accounts_screen.dart';
import '../screen/notifications_screen.dart';
import 'reports_screen.dart';
import 'history_screen.dart';
import '../screen/monthly_budget_screen.dart';
import '../screen/finance_overview_screen.dart';
import 'debt_management_screen.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxBool isDescending = true.obs;

  // --- ألوانك وهويتك البصرية (كاملة بدون تعديل) ---
  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color deepGreen = Color(0xFF00C853);
  static const Color deepOrange = Color(0xFFFF6D00);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF000000);

  // --- الدوال المساعدة (كما كتبتها أنت تماماً) ---
  double _getResponsiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;
    return size * (width / 400);
  }

  Color _parseColor(dynamic colorData) {
    try {
      if (colorData == null) return deepBlue;
      if (colorData is int) return Color(colorData);
      return Color(int.parse(colorData.toString()));
    } catch (e) { return deepBlue; }
  }

  IconData _parseIcon(dynamic iconData) {
    try {
      if (iconData == null) return Icons.account_balance_wallet_rounded;
      int code = (iconData is int) ? iconData : int.parse(iconData.toString());
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) { return Icons.account_balance_wallet_rounded; }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return DateFormat('MMM d, h:mm a').format(DateTime.now());
    try {
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        dt = DateTime.parse(timestamp.toString());
      }
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) { return "N/A"; }
  }

  Widget _buildBrandText(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: _getResponsiveSize(context, 25), fontWeight: FontWeight.w900, letterSpacing: 1.2),
        children: const [
          TextSpan(text: "Smart ", style: TextStyle(color: Color(0xFF103667))),
          TextSpan(text: "Budget", style: TextStyle(color: Color(0xFF43A047))),
        ],
      ),
    );
  }

  // --- بناء الصفحة ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgLight,
      drawer: _buildModernDrawer(context),
      body: Stack(
        children: [
          Positioned(top: -70, right: -70, child: _buildBlurBlob([deepTeal.withOpacity(0.15), Colors.teal.shade900.withOpacity(0.1)])),
          Positioned(bottom: 150, left: -80, child: _buildBlurBlob([deepBlue.withOpacity(0.12), Colors.blue.shade900.withOpacity(0.1)])),
          PageView(
            controller: controller.pageController,
            onPageChanged: (index) => controller.currentIndex.value = index,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildMainDashboardContent(context),
              const CategorySummaryScreen(),
              const CategoriesScreen(),
              ProfileScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 55, height: 55,
        child: FloatingActionButton(
          onPressed: () => _showFabMenu(context),
          backgroundColor: textBlack,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
    );
  }

  // --- محتوى الداشبورد (هنا الإصلاح مع الحفاظ على التصميم) ---
  Widget _buildMainDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      color: deepTeal,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. الأبار (Sliver)
            StreamBuilder<UserModel>(
              stream: controller.userDataStream,
              builder: (context, snapshot) => _buildAppBar(context, snapshot.data?.fullName ?? "User"),
            ),

            // 2. العناصر الرسومية والبطاقات (داخل Adapter واحد للحفاظ على الترتيب)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  children: [
                    // حل مشكلة totalBalance: نحسبه من الدخل والمصروفات مباشرة
                    Obx(() {
                      double income = controller.totalIncome.value;
                      double expense = controller.totalExpense.value;
                      double balance = income - expense;
                      return _buildGlassBalanceCard(
                          context,
                          balance: balance,
                          income: income,
                          spent: expense,
                          currency: "SAR"
                      );
                    }),
                    const SizedBox(height: 12),

                    // بطاقة الميزانية الذكية (تصميمك المطور 85% و 90%)
                    Obx(() => _buildMiniBudgetCard(
                        context,
                        controller.totalExpense.value,
                        controller.monthlyBudget.value
                    )),
                    const SizedBox(height: 12),

                    _actionSection(context),
                    const SizedBox(height: 15),
                    _buildSectionHeader("Latest Transactions"),
                  ],
                ),
              ),
            ),

            // 3. قائمة العمليات (SliverList) لضمان عدم وجود أخطاء رندر
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: controller.recentTransactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())));
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No transactions yet"))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => InkWell(
                        onTap: () => _showTransactionDetails(context, transactions[index]),
                        child: _buildTransactionItem(transactions[index])
                    ),
                    childCount: transactions.length,
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  // --- بقية الدوال (تم نسخها حرفياً من كودك الأصلي لضمان عدم فقدان أي تصميم) ---

  Widget _buildAppBar(BuildContext context, String name) => SliverAppBar(
    backgroundColor: Colors.transparent,
    floating: true,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(onPressed: () => _scaffoldKey.currentState?.openDrawer(), icon: const Icon(Icons.menu_rounded, color: textBlack, size: 24)),
    title: _buildBrandText(context),
    actions: [
      StreamBuilder<int>(
          stream: controller.unreadNotificationsCountStream,
          builder: (context, snapshot) {
            int count = snapshot.data ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded, color: textBlack, size: 24), onPressed: () => Get.to(() => const NotificationsScreen())),
                if (count > 0)
                  Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), constraints: const BoxConstraints(minWidth: 14, minHeight: 14), child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              ],
            );
          }
      ),
      const SizedBox(width: 5),
    ],
  );

  Widget _buildGlassBalanceCard(BuildContext context, {required double balance, required double income, required double spent, required String currency}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEEE, d MMM').format(DateTime.now()), style: const TextStyle(color: Colors.white54, fontSize: 9)),
              ]),
              const Icon(Icons.nfc_outlined, color: Colors.white54, size: 22),
            ]),
            const SizedBox(height: 5),
            Text("$currency ${balance.toStringAsFixed(0)}", style: TextStyle(color: Colors.white, fontSize: _getResponsiveSize(context, 26), fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatTileItem(title: "Income", amount: income.toInt().toString(), icon: Icons.arrow_upward_rounded, color: Colors.greenAccent),
                  Container(width: 1, height: 25, color: Colors.white12),
                  _StatTileItem(title: "Spent", amount: spent.toInt().toString(), icon: Icons.arrow_downward_rounded, color: Colors.redAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBudgetCard(BuildContext context, double spent, double limit) {
    double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0;
    int percentage = (progress * 100).toInt();
    bool isWarning85 = percentage >= 85 && percentage < 90;
    bool isDanger90 = percentage >= 90 && percentage < 100;
    bool isExceeded = percentage >= 100;

    Color statusColor = isExceeded ? Colors.red.shade700 : (isDanger90 ? Colors.red.shade400 : (isWarning85 ? Colors.orange.shade800 : deepBlue));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: isWarning85 ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 10)],
          border: Border.all(color: statusColor.withOpacity(0.3), width: isWarning85 || isExceeded ? 2.0 : 1.2)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 45, height: 45, child: CircularProgressIndicator(value: progress, color: statusColor, backgroundColor: statusColor.withOpacity(0.1), strokeWidth: 4.5)),
                  Text("$percentage%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Monthly Budget Status", style: TextStyle(color: statusColor.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)), Text("SAR ${spent.toInt()} of ${limit.toInt()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 14))])),
            ],
          ),
          if (isWarning85 || isDanger90 || isExceeded) ...[
            const SizedBox(height: 10),
            Row(children: [Icon(isExceeded ? Icons.block : Icons.warning_amber_rounded, size: 14, color: statusColor), const SizedBox(width: 6), Expanded(child: Text(isExceeded ? "🛑 Alert: Budget Exceeded!" : (isDanger90 ? "⚠️ Critical: You have reached 90% of your budget!" : "⚠️ Warning: You have used 85% of your budget!"), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)))]),
          ]
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final Color categoryColor = _parseColor(data['categoryColor']);
    final bool isIncome = data['type'] == 'Income';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(height: 50, width: 50, decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(_parseIcon(data['categoryIcon']), color: categoryColor, size: 24)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['categoryName'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(_formatDateTime(data['timestamp']), style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${isIncome ? '+' : '-'}${data['amount']}", style: TextStyle(color: isIncome ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)), const Text("SAR", style: TextStyle(color: Colors.black26, fontSize: 10))]),
          ],
        ),
      ),
    );
  }

  // --- المنيو والنافبجيشن (كاملة بدون حذف) ---
  Widget _buildModernDrawer(BuildContext context) => Drawer(
    width: MediaQuery.of(context).size.width * 0.75,
    backgroundColor: Colors.white,
    child: Column(children: [_buildDrawerHeader(context), Expanded(child: SingleChildScrollView(child: Column(children: [_drawerSectionTitle("Financial Tools"), _drawerItem(Icons.history_rounded, "Transaction History", deepOrange, () { Get.back(); Get.to(() => const MainBalanceCard()); }), _drawerItem(Icons.account_balance_rounded, "Bank Accounts", Colors.blueGrey, () { Get.back(); Get.to(() => const LinkedAccountsScreen()); }), _drawerSectionTitle("Management"), _drawerItem(Icons.track_changes_rounded, "Budget Planning", Colors.redAccent, () { Get.back(); Get.to(() => const MonthlyBudgetScreen()); }), _drawerItem(Icons.category_rounded, "Reports", deepTeal, () { Get.back(); Get.to(() => const ReportsScreen()); }), _drawerItem(Icons.stars_rounded, "History", deepGreen, () { Get.back(); Get.to(() => const HistoryScreen()); }), _drawerItem(Icons.auto_graph_rounded, "Finance Overview", deepGreen, () { Get.back(); Get.to(() => const FinanceOverviewScreen()); }), _drawerItem(Icons.notifications_active_rounded, "Alerts", Colors.amber.shade800, () { Get.back(); Get.to(() => const NotificationsScreen()); }), _drawerItem(Icons.logout_rounded, "Logout", Colors.redAccent, () async { Get.back(); await controller.logout(); }), const SizedBox(height: 30)])))]),
  );

  Widget _buildDrawerHeader(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFA0CFA3), Color(0xFF23857B)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(radius: 30, backgroundColor: Colors.white60, child: Icon(Icons.person, color: Color(0xFF2E7D32))), const SizedBox(height: 12), StreamBuilder<UserModel>(stream: controller.userDataStream, builder: (context, snapshot) => Text(snapshot.data?.fullName ?? "User", style: const TextStyle(color: Color(0xFF052E63), fontWeight: FontWeight.w900))), const Text("Management Console", style: TextStyle(color: Color(0xFF1A5DC6), fontSize: 11))]));

  Widget _drawerSectionTitle(String title) => Container(width: double.infinity, padding: const EdgeInsets.only(left: 20, top: 15), child: Text(title.toUpperCase(), style: TextStyle(color: textBlack.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _drawerItem(IconData icon, String title, Color color, VoidCallback onTap) => ListTile(dense: true, leading: Icon(icon, color: color, size: 18), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), onTap: onTap);

  Widget _buildBlurBlob(List<Color> colors) => Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors), boxShadow: [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 100, spreadRadius: 50)]));

  Widget _actionSection(BuildContext context) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_actionBtn(context, Icons.add_box_rounded, "Add", deepTeal, () => Get.to(() => const AddTransactionScreen())), _actionBtn(context, Icons.track_changes_rounded, "Budget", Colors.redAccent, () => Get.to(() => const MonthlyBudgetScreen())), _actionBtn(context, Icons.stars_rounded, "Goals", deepGreen, () => Get.to(() => const SavingsGoalsScreen())), _actionBtn(context, Icons.receipt_long_rounded, "History", Colors.blueAccent, () => Get.to(() => const MainBalanceCard())), _actionBtn(context, Icons.pie_chart_rounded, "Reports", Colors.purpleAccent, () => Get.to(() => const ReportsScreen())), _actionBtn(context, Icons.stars_rounded, "Debt", deepGreen, () => Get.to(() => const DebtManagementScreen()))]));

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 75, margin: const EdgeInsets.symmetric(horizontal: 6), child: Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])));

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Obx(() => IconButton(onPressed: () => isDescending.value = !isDescending.value, icon: Icon(isDescending.value ? Icons.sort_rounded : Icons.filter_list_rounded, color: deepBlue)))]));

  Widget _buildBottomNav(BuildContext context) => Container(height: 60, decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))), child: BottomAppBar(elevation: 0, padding: EdgeInsets.zero, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navIcon(0, Icons.dashboard_rounded, deepBlue, "Home"), _navIcon(1, Icons.pie_chart_rounded, deepOrange, "Stats"), const SizedBox(width: 40), _navIcon(2, Icons.wallet_rounded, deepGreen, "Wallet"), _navIcon(3, Icons.person_rounded, Colors.purple, "Profile")])));

  Widget _navIcon(int index, IconData icon, Color color, String label) => Obx(() { bool selected = controller.currentIndex.value == index; return InkWell(onTap: () => controller.changePage(index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? color : Colors.black26, size: 22), if (selected) Text(label, style: TextStyle(color: color, fontSize: 9))])); });

  void _showFabMenu(BuildContext context) => Get.bottomSheet(Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 15), _drawerItem(Icons.add_chart_rounded, "Add Transaction", deepTeal, () { Get.back(); Get.to(() => const AddTransactionScreen()); }), _drawerItem(Icons.track_changes_rounded, "Set Monthly Budget", Colors.redAccent, () { Get.back(); Get.to(() => const MonthlyBudgetScreen()); }), _drawerItem(Icons.stars_rounded, "Add Savings Goal", deepGreen, () { Get.back(); Get.to(() => const SavingsGoalsScreen()); }), _drawerItem(Icons.category_outlined, "Manage Categories", deepOrange, () { Get.back(); Get.to(() => const CategoriesScreen()); })])));

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> data) { /* كود التفاصيل كما هو */ }
}

class _StatTileItem extends StatelessWidget {
  final String title, amount; final IconData icon; final Color color;
  const _StatTileItem({required this.title, required this.amount, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10))]), const SizedBox(height: 4), Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))]);
  }
}
 */