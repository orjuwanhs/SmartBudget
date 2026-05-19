import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LinkedAccountsScreen extends StatelessWidget {
  const LinkedAccountsScreen({super.key});

  // ميثود مساعدة لتصغير الأحجام بناءً على عرض الشاشة
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Linked Accounts",
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)), // خط ملموم
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1565C0), size: 24),
            onPressed: () => _showAddAccountSheet(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 5, bottom: 12),
              child: Text("Your Cards",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
            ),

            // بطاقة بنك الراجحي - حجم ملموم
            _buildBankCard(
              context,
              bankName: "Al Rajhi Bank",
              balance: "24,500.00",
              cardNumber: "**** 4290", // اختصار الرقم
              color: const Color(0xFF1B5E20),
              logo: Icons.account_balance_rounded,
            ),

            const SizedBox(height: 12),

            // بطاقة بنك STC Pay - حجم ملموم
            _buildBankCard(
              context,
              bankName: "STC Pay",
              balance: "1,200.50",
              cardNumber: "**** 8812",
              color: const Color(0xFF4A148C),
              logo: Icons.account_balance_wallet_rounded,
            ),

            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.only(left: 5, bottom: 12),
              child: Text("Account Details",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
            ),

            _buildAccountDetailItem("Total Liquidity", "25,700.50 SAR", Icons.insights_rounded, Colors.blue),
            _buildAccountDetailItem("Active Cards", "2 Cards", Icons.credit_card_rounded, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(
      BuildContext context, {
        required String bankName,
        required String balance,
        required String cardNumber,
        required Color color,
        required IconData logo
      }) {
    return Container(
      width: double.infinity,
      height: 160, // تصغير الارتفاع من 200 إلى 160
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20), // زوايا أرشق
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 6))
        ],
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20), // تقليل البادينج
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(logo, color: Colors.white, size: 24),
              Text(bankName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Current Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("SAR $balance",
                  style: TextStyle(color: Colors.white, fontSize: _res(context, 22), fontWeight: FontWeight.w900)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cardNumber,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const Icon(Icons.contactless_rounded, color: Colors.white54, size: 18),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAccountDetailItem(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), // ملموم أكثر
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black.withOpacity(0.03))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Connect New Bank",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  hintText: "Bank Name",
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                minimumSize: const Size(double.infinity, 45),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Get.back(),
              child: const Text("Secure Connect",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}