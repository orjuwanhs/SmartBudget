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

// ... (نفس استيراداتك السابقة بدون تغيير)

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxBool isDescending = true.obs;

  // ألوانك الثابتة
  static const Color deepTeal = Color(0xFF00796B);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color deepGreen = Color(0xFF00C853);
  static const Color deepOrange = Color(0xFFFF6D00);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Color(0xFF000000);

  // الدوال المساعدة (نفس دوالك السابقة)
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

  Widget _buildSparkline(Color color) {
    return SizedBox(
      width: 40,
      height: 20,
      child: CustomPaint(painter: SparklinePainter(color: color)),
    );
  }

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

  // --- (نفس كود المنيو الجانبي DrawerHeader و DrawerItem بدون أي حذف) ---
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
                        Future.delayed(const Duration(milliseconds: 300), () {
                          Get.delete<DashboardController>(force: true);
                        });
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

  // --- التعديل الجوهري هنا في ربط البيانات الحقيقية ---
  Widget _buildMainDashboardContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      color: deepTeal,
      child: SafeArea(
        child: StreamBuilder<UserModel>(
          stream: controller.userDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, snapshot.data?.fullName ?? "User"),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        // مصلح: استخدام Obx لربط الرصيد والدخل والمصروفات بالبيانات الحقيقية
                        Obx(() {
                          // حساب الرصيد الصافي
                          double totalBal = controller.totalIncome.value - controller.totalExpense.value;
                          return _buildGlassBalanceCard(
                              context,
                              balance: totalBal,
                              income: controller.totalIncome.value,
                              spent: controller.totalExpense.value,
                              currency: "SAR"
                          );
                        }),
                        const SizedBox(height: 12),

                        // كرت الميزانية الذكية
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

                _buildTransactionList(context),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- (بقية الدوال المساعدة كما هي بدون حذف لتشغيل الصفحة) ---

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

    // تحديد الحالات بناءً على النسب
    bool isWarning85 = percentage >= 85 && percentage < 90; // الحالة الجديدة المطلوبة
    bool isDanger90 = percentage >= 90 && percentage < 100;
    bool isExceeded = percentage >= 100;

    // تحديد اللون الأساسي للبطاقة بناءً على النسبة
    Color statusColor;
    if (isExceeded) {
      statusColor = Colors.red.shade700;
    } else if (isDanger90) {
      statusColor = Colors.red.shade400; // أحمر فاتح للـ 90%
    } else if (isWarning85) {
      statusColor = Colors.orange.shade800; // اللون البرتقالي المطلوب للـ 85%
    } else {
      statusColor = deepBlue; // اللون الطبيعي
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: isWarning85 ? Colors.orange.shade50 : Colors.white, // تغيير خلفية البطاقة للبرتقالي الفاتح جداً عند التحذير
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1
            )
          ],
          border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: isWarning85 || isExceeded ? 2.0 : 1.2 // زيادة سمك الإطار عند التحذير
          )
      ),
      child: Column( // تم تغيير الصف إلى عمود لإضافة الرسالة بالأسفل
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                      width: 45,
                      height: 45,
                      child: CircularProgressIndicator(
                          value: progress,
                          color: statusColor,
                          backgroundColor: statusColor.withOpacity(0.1),
                          strokeWidth: 4.5
                      )
                  ),
                  Text("$percentage%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly Budget Status", style: TextStyle(color: statusColor.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)),
                        Text("SAR ${spent.toInt()} of ${limit.toInt()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 14)),
                      ]
                  )
              ),
            ],
          ),

          // إضافة رسائل التحذير بالأسفل بناءً على الحالة
          if (isWarning85 || isDanger90 || isExceeded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    isExceeded ? Icons.block : Icons.warning_amber_rounded,
                    size: 14,
                    color: statusColor
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExceeded
                        ? "🛑 Alert: Budget Exceeded!"
                        : (isDanger90
                        ? "⚠️ Critical: You have reached 90% of your budget!"
                        : "⚠️ Warning: You have used 85% of your budget!"),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    // تحويل الألوان والأيقونات من نصوص/أرقام إلى عناصر Flutter
    final Color categoryColor = _parseColor(data['categoryColor']);
    final bool isIncome = data['type'] == 'Income';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة الفئة
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _parseIcon(data['categoryIcon']),
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            // تفاصيل العملية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['categoryName'] ?? "General",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatDateTime(data['timestamp']),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            // المبلغ
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isIncome ? '+' : '-'}${data['amount']}",
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "SAR",
                  style: TextStyle(color: Colors.black26, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- (نفس دالة التفاصيل _showTransactionDetails بدون تغيير) ---
  void _showTransactionDetails(BuildContext context, Map<String, dynamic> data) {
    final Color c = _parseColor(data['categoryColor']);
    final bool isInc = data['type'] == 'Income';
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(_parseIcon(data['categoryIcon']), color: c, size: 40)),
              const SizedBox(height: 12),
              Text(data['categoryName'] ?? "General", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text("${isInc ? '+' : '-'}${data['amount']} SAR", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isInc ? Colors.green.shade600 : Colors.redAccent)),
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
                        const Row(children: [Icon(Icons.notes_rounded, size: 14, color: Colors.black26), SizedBox(width: 5), Text("Note", style: TextStyle(color: Colors.black26, fontSize: 10))]),
                        const SizedBox(height: 5),
                        Text(data['note']?.toString() ?? "No notes.", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(onPressed: () => Get.back(), style: ElevatedButton.styleFrom(backgroundColor: deepBlue, minimumSize: const Size(double.infinity, 50)), child: const Text("CLOSE", style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailRow(String label, String value, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.black38, fontSize: 12)), Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900))]);

  Widget _actionSection(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
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

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 75, margin: const EdgeInsets.symmetric(horizontal: 6), child: Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])));

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      Obx(() => IconButton(onPressed: () => isDescending.value = !isDescending.value, icon: Icon(isDescending.value ? Icons.sort_rounded : Icons.filter_list_rounded, color: deepBlue))),
    ]),
  );

  Widget _buildBottomNav(BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
    child: BottomAppBar(
      elevation: 0, padding: EdgeInsets.zero,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navIcon(0, Icons.dashboard_rounded, deepBlue, "Home"),
        _navIcon(1, Icons.pie_chart_rounded, deepOrange, "Stats"),
        const SizedBox(width: 40),
        _navIcon(2, Icons.wallet_rounded, deepGreen, "Wallet"),
        _navIcon(3, Icons.person_rounded, Colors.purple, "Profile"),
      ]),
    ),
  );

  Widget _navIcon(int index, IconData icon, Color color, String label) => Obx(() {
    bool selected = controller.currentIndex.value == index;
    return InkWell(onTap: () => controller.changePage(index), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? color : Colors.black26, size: 22), if (selected) Text(label, style: TextStyle(color: color, fontSize: 9))]));
  });

  void _showFabMenu(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _drawerItem(Icons.add_chart_rounded, "Add Transaction", deepTeal, () { Get.back(); Get.to(() => const AddTransactionScreen()); }),
          _drawerItem(Icons.track_changes_rounded, "Set Monthly Budget", Colors.redAccent, () { Get.back(); Get.to(() => const MonthlyBudgetScreen()); }),
          _drawerItem(Icons.stars_rounded, "Add Savings Goal", deepGreen, () { Get.back(); Get.to(() => const SavingsGoalsScreen()); }),
          _drawerItem(Icons.category_outlined, "Manage Categories", deepOrange, () { Get.back(); Get.to(() => const CategoriesScreen()); }),
        ]),
      ),
    );
  }
}

// --- (نفس كلاس SparklinePainter و _StatTileItem بدون أي حذف) ---
class SparklinePainter extends CustomPainter {
  final Color color;
  SparklinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.5)..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.3);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
