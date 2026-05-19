import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditTransactionPage({super.key, required this.data});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final DashboardController controller = Get.find<DashboardController>();

  late TextEditingController amountController;
  late String selectedType;
  late String categoryName;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: widget.data['amount'].toString());
    selectedType = widget.data['type'] ?? "Expense";
    categoryName = widget.data['categoryName'] ?? "General";
  }

  // ميثود متجاوبة لتصغير الأحجام
  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("EDIT TRANSACTION",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)), // خط أصغر
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50, // تقليل ارتفاع الهيدر
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // حواف ملمومة
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Transaction Type"),
            const SizedBox(height: 8),
            _buildTypeToggle(),
            const SizedBox(height: 20),

            _buildSectionLabel("Amount (SAR)"),
            const SizedBox(height: 8),
            _buildAmountField(context),
            const SizedBox(height: 20),

            _buildSectionLabel("Category"),
            const SizedBox(height: 8),
            _buildCategoryTile(),

            const SizedBox(height: 40), // تقليل المسافة قبل الزر
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.black38, fontWeight: FontWeight.w900, fontSize: 10));
  }

  Widget _buildTypeToggle() {
    return Row(
      children: ['Income', 'Expense'].map((type) {
        bool isSelected = selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: type == 'Income' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12), // تقليل الارتفاع
              decoration: BoxDecoration(
                color: isSelected ? (type == 'Income' ? Colors.green : Colors.orange) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
              ),
              child: Center(
                child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: _res(context, 18), fontWeight: FontWeight.w900),
        decoration: const InputDecoration(border: InputBorder.none, hintText: "0.00"),
      ),
    );
  }

  Widget _buildCategoryTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), // ملموم أكثر
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          const Text("Locked", style: TextStyle(color: Colors.black26, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    Color activeColor = selectedType == 'Income' ? Colors.green : Colors.orange;

    return SizedBox(
      width: double.infinity,
      height: 50, // تصغير ارتفاع الزر من 60 إلى 50
      child: ElevatedButton(
        onPressed: _updateTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2, // تقليل الظل
          shadowColor: activeColor.withOpacity(0.3),
        ),
        child: const Text(
            "UPDATE TRANSACTION",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)
        ),
      ),
    );
  }

  void _updateTransaction() async {
    double? amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        "Invalid Amount",
        "Please enter a valid amount",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM, // ليكون ملموم أكثر في العرض
      );
      return;
    }

    await controller.updateTransaction(
      widget.data['id'],
      {
        'amount': amount,
        'type': selectedType,
        'category_name': categoryName,
        'categoryName': categoryName,
        'category_icon': widget.data['category_icon'] ?? widget.data['categoryIcon'],
        'category_color': widget.data['category_color'] ?? widget.data['categoryColor'],
      },
    );
  }
}