import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool isExpense = true;
  final CategoryController controller = Get.put(CategoryController());

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textBlack = Colors.black;

  IconData _selectedIcon = Icons.stars;
  Color _selectedColor = const Color(0xFF1A73E8);
  bool _dialogIsExpense = true;

  double _res(BuildContext context, double size) => size * (MediaQuery.of(context).size.width / 400);

  Color _parseColor(dynamic colorData) {
    if (colorData == null) return Colors.grey;
    try {
      if (colorData is int) return Color(colorData);
      return Color(int.parse(colorData.toString()));
    } catch (e) { return const Color(0xFF1A73E8); }
  }

  IconData _parseIcon(dynamic iconData) {
    if (iconData == null) return Icons.category;
    try {
      int code = (iconData is int) ? iconData : int.parse(iconData.toString());
      return IconData(code, fontFamily: 'MaterialIcons');
    } catch (e) { return Icons.category; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildLightAppBar("Categories"),
            const SizedBox(height: 5), // تقليل المسافة
            _buildToggleTab(),
            const SizedBox(height: 15),
            Expanded(child: _buildCategoriesList()),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 50, height: 50, // تصغير حجم الزر العائم
        child: FloatingActionButton(
          onPressed: () => _showCategoryDialog(context),
          backgroundColor: const Color(0xFF00897B),
          elevation: 3,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildLightAppBar(String title) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textBlack, size: 18),
          onPressed: () => Get.back(),
        ),
        Text(title, style: const TextStyle(color: textBlack, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    ),
  );

  Widget _buildToggleTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4), // تقليل البادينج الداخلي
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(15)), // زوايا أصغر
      child: Row(
        children: [
          _tabBtn("Expenses", isExpense, () => setState(() => isExpense = true)),
          _tabBtn("Income", !isExpense, () => setState(() => isExpense = false)),
        ],
      ),
    );
  }

  Widget _tabBtn(String title, bool active, VoidCallback onTap) {
    Color activeColor = isExpense ? Colors.redAccent.shade700 : Colors.green.shade600;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10), // تقليل الارتفاع
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(title,
                style: TextStyle(
                    color: active ? Colors.white : Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.getCategories(isExpense),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No categories found", style: TextStyle(color: Colors.black26, fontSize: 12)));
        }

        final list = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            bool isSystem = item['is_system'] ?? false;
            Color catColor = _parseColor(item['color']);
            IconData catIcon = _parseIcon(item['icon']);

            Widget categoryCard = Container(
              margin: const EdgeInsets.only(bottom: 8), // تقليل المسافة بين البطاقات
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))
                  ],
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                onTap: isSystem ? null : () => _showCategoryDialog(context, item: item),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // ملموم أكثر
                leading: Container(
                  padding: const EdgeInsets.all(8), // تصغير الأيقونة
                  decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                title: Text(item['name'] ?? "Unknown",
                    style: const TextStyle(color: textBlack, fontWeight: FontWeight.w800, fontSize: 14)),
                trailing: isSystem
                    ? const Icon(Icons.lock_outline, color: Colors.black12, size: 16)
                    : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => _confirmDelete(item),
                ),
              ),
            );

            if (isSystem) return categoryCard;

            return Dismissible(
              key: Key(item['id']),
              direction: DismissDirection.endToStart,
              onDismissed: (dir) => controller.deleteCategory(item['id']),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 22),
              ),
              child: categoryCard,
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      radius: 15,
      title: "Delete Category",
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      middleText: "Delete this category?",
      middleTextStyle: const TextStyle(fontSize: 12),
      textConfirm: "Delete",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteCategory(item['id']);
        Get.back();
      },
      textCancel: "Cancel",
      cancelTextColor: Colors.black38,
    );
  }

  // --- الميثود المحدثة لحل مشكلة الـ Overflow وتوافق الشاشات ---
  void _showCategoryDialog(BuildContext context, {Map<String, dynamic>? item}) {
    bool isEdit = item != null;
    TextEditingController nameController = TextEditingController(text: isEdit ? item['name'] : "");

    if (isEdit) {
      _selectedIcon = _parseIcon(item['icon']);
      _selectedColor = _parseColor(item['color']);
      _dialogIsExpense = (item['type'] == 'expense');
    } else {
      _selectedIcon = Icons.stars;
      _selectedColor = const Color(0xFF1A73E8);
      _dialogIsExpense = isExpense;
    }

    List<IconData> icons = [Icons.stars, Icons.shopping_cart, Icons.work, Icons.home, Icons.fastfood, Icons.directions_car, Icons.fitness_center, Icons.school];
    List<Color> colors = [const Color(0xFF1A73E8), Colors.orange, Colors.pinkAccent, Colors.green, Colors.purpleAccent, Colors.redAccent];

    Get.bottomSheet(
      isScrollControlled: true, // مهم جداً للسماح للنافذة بالارتفاع مع لوحة المفاتيح
      Container(
        padding: EdgeInsets.only(
          top: 20, left: 20, right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, // دفع المحتوى للأعلى عند ظهور الكيبورد
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView( // يسمح بالتمرير إذا كان المحتوى أكبر من الشاشة
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(isEdit ? "Update Category" : "New Category", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    hintText: "Category Name",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 15),
              StatefulBuilder(builder: (context, setDialogState) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dialogTypeBtn(setDialogState, "Expense", _dialogIsExpense, true),
                        const SizedBox(width: 10),
                        _dialogTypeBtn(setDialogState, "Income", !_dialogIsExpense, false),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Select Icon", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: icons.map((icon) => GestureDetector(
                        onTap: () => setDialogState(() => _selectedIcon = icon),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: _selectedIcon == icon ? _selectedColor.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                          child: Icon(icon, color: _selectedIcon == icon ? _selectedColor : Colors.black26, size: 20),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text("Select Color", style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      alignment: WrapAlignment.center,
                      children: colors.map((color) => GestureDetector(
                        onTap: () => setDialogState(() => _selectedColor = color),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: color,
                          child: _selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                        ),
                      )).toList(),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      if (isEdit) {
                        controller.updateCategory(id: item['id'], name: nameController.text, icon: _selectedIcon.codePoint, color: _selectedColor.value);
                      } else {
                        controller.addCategory(name: nameController.text, icon: _selectedIcon.codePoint, color: _selectedColor.value, isExpense: _dialogIsExpense);
                      }
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(isEdit ? "UPDATE" : "ADD CATEGORY", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
  Widget _dialogTypeBtn(StateSetter setDialogState, String label, bool selected, bool toExpense) {
    return GestureDetector(
      onTap: () => setDialogState(() => _dialogIsExpense = toExpense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (toExpense ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? (toExpense ? Colors.redAccent : Colors.green) : Colors.black12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? (toExpense ? Colors.redAccent : Colors.green) : Colors.black38)),
      ),
    );
  }
}