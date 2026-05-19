import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/dashboard_controller.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/category_controller.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final CategoryController categoryController = Get.put(CategoryController());
  final DashboardController dashboard = Get.put(DashboardController());
  final TransactionController controller = Get.put(TransactionController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedType = "Expense";
  Map<String, dynamic>? selectedCategory;
  DateTime selectedDate = DateTime.now();

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Colors.black;
  static const Color deepOrange = Color(0xFFFF6D00);

  double _res(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.width / 400);
  }

  IconData _parseIcon(dynamic iconData) {
    try {
      int code = (iconData is int) ? iconData : int.parse(iconData.toString());
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) { return Icons.category_rounded; }
  }

  Color _parseColor(dynamic colorData) {
    try {
      if (colorData is int) return Color(colorData);
      return Color(int.parse(colorData.toString()));
    } catch (e) { return deepOrange; }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = selectedType == 'Income' ? Colors.green.shade700 : deepOrange;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          _buildDynamicGlow(activeColor),
          SafeArea(
            child: Column(
              children: [
                _buildModernAppBar("New Transaction", activeColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: Container(
                        width: screenWidth > 600 ? 400 : screenWidth * 0.94,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  const Text("AMOUNT", style: TextStyle(color: Colors.black45, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                                  TextField(
                                    controller: amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: textBlack, fontSize: _res(context, 32), fontWeight: FontWeight.w900),
                                    decoration: InputDecoration(
                                      hintText: "0.00",
                                      hintStyle: const TextStyle(color: Colors.black12),
                                      prefixText: "SAR ",
                                      prefixStyle: TextStyle(color: activeColor, fontSize: 14, fontWeight: FontWeight.bold),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTypeSelector(activeColor),
                            const SizedBox(height: 20),
                            _buildSectionTitle("SELECT CATEGORY"),
                            const SizedBox(height: 10),
                            _buildHorizontalCategoryList(),
                            const SizedBox(height: 20),
                            _buildSectionTitle("NOTES"),
                            const SizedBox(height: 8),
                            _buildNoteField(activeColor),
                            const SizedBox(height: 20),
                            _buildSaveButton(activeColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(String title, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textBlack, fontSize: 16, fontWeight: FontWeight.w900)),
                Text(DateFormat('dd MMM yyyy').format(selectedDate),
                    style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calendar_month_rounded, color: activeColor, size: 18),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildHorizontalCategoryList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: categoryController.getCategories(selectedType == "Expense"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }
        var categories = snapshot.data ?? [];

        return SizedBox(
          height: 90,
          child: ListView.builder(
            key: PageStorageKey<String>('cat_list_${selectedType}'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              var cat = categories[index];
              bool isSelected = selectedCategory?['id'] == cat['id'];
              Color catColor = _parseColor(cat['color']);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => selectedCategory = cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 75,
                  margin: const EdgeInsets.only(right: 10, bottom: 4, top: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? catColor.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? catColor : Colors.black.withOpacity(0.05),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? catColor : catColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_parseIcon(cat['icon']), color: isSelected ? Colors.white : catColor, size: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat['name'],
                        style: TextStyle(
                            color: isSelected ? textBlack : Colors.black45,
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(Color activeColor) {
    return Container(
      width: double.infinity, height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), color: activeColor,
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _startSubmissionProcess,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        child: const Text(
            "SAVE TRANSACTION",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)
        ),
      ),
    );
  }

  // دالة تبدأ عملية التحقق ثم الإرسال
  void _startSubmissionProcess() {
    final enteredAmount = double.tryParse(amountController.text) ?? 0.0;

    if (enteredAmount <= 0 || selectedCategory == null) {
      _finalSubmit();
      return;
    }

    controller.validateAndConfirm(
      amount: enteredAmount,
      type: selectedType,
      categoryName: selectedCategory!['name'],
      onConfirmed: () {
        _finalSubmit();
      },
    );
  }

  // الدالة النهائية للإرسال (تم توحيدها وحذف التكرار)
  void _finalSubmit() {
    if (amountController.text.isEmpty || selectedCategory == null) {
      HapticFeedback.heavyImpact();
      Get.snackbar(
          "Missing Data",
          "Select a category and enter amount",
          backgroundColor: deepOrange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20)
      );
      return;
    }

    double? amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;

    controller.addTransaction(
      categoryId: selectedCategory!['id'],
      amount: amount,
      type: selectedType,
      categoryName: selectedCategory!['name'],
      categoryIcon: selectedCategory!['icon'].toString(),
      categoryColor: selectedCategory!['color'].toString(),
      note: noteController.text,
      date: selectedDate,
    );
  }

  Widget _buildTypeSelector(Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _buildTypeBtn("Expense", deepOrange),
          _buildTypeBtn("Income", Colors.green.shade600),
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String type, Color color) {
    bool isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            selectedType = type;
            selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black38, fontSize: 12, fontWeight: FontWeight.w900))),
        ),
      ),
    );
  }

  void _pickDate() async {
    HapticFeedback.mediumImpact();
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: selectedType == 'Income' ? Colors.green : deepOrange),
            ),
            child: child!,
          );
        }
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Widget _buildNoteField(Color activeColor) {
    return TextField(
      controller: noteController,
      style: const TextStyle(color: textBlack, fontWeight: FontWeight.w700, fontSize: 13),
      decoration: InputDecoration(
        hintText: "Add a short note...",
        hintStyle: const TextStyle(color: Colors.black12, fontSize: 12),
        filled: true, fillColor: bgLight,
        contentPadding: const EdgeInsets.all(12),
        isDense: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.black.withOpacity(0.03))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: activeColor.withOpacity(0.5), width: 1.5)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1));
  }

  Widget _buildDynamicGlow(Color activeColor) {
    return Positioned(
      top: -100, left: 50, right: 50,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 250, height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor.withOpacity(0.02),
          boxShadow: [BoxShadow(color: activeColor.withOpacity(0.05), blurRadius: 80, spreadRadius: 30)],
        ),
      ),
    );
  }
}