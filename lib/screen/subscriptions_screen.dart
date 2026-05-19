import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';

// 1. تعريف موديل البيانات (الاشتراك)
class Subscription {
  final String name;
  final double amount;
  final String date;

  Subscription({required this.name, required this.amount, required this.date});
}

class SubscriptionsScreen extends StatelessWidget {
  SubscriptionsScreen({super.key});

  // 2. ربط الصفحة بالمتحكم (Controller)
  final SubscriptionController controller = Get.put(SubscriptionController());

  // 3. دالة إظهار نافذة الإضافة
  void _showAddSubscriptionSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView( // لضمان عدم حدوث خطأ عند ظهور لوحة المفاتيح
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Subscription",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Subscription Name",
                  prefixIcon: const Icon(Icons.label_important_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (SAR)",
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Payment Date (e.g. Every 1st)",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      // حفظ البيانات في Firebase عبر الكنترولر
                      await controller.addSubscriptionToDB(
                        nameController.text,
                        double.tryParse(amountController.text) ?? 0.0,
                        dateController.text,
                      );
                      Get.back(); // إغلاق النافذة
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("My Subscriptions"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      // 4. عرض القائمة التي تتحدث تلقائياً من Firebase
      body: Obx(() {
        if (controller.mySubscriptions.isEmpty) {
          return const Center(child: Text("No active subscriptions found."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: controller.mySubscriptions.length,
          itemBuilder: (context, index) {
            final sub = controller.mySubscriptions[index];
            return _buildSubscriptionCard(sub);
          },
        );
      }),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionSheet(context),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // ويدجت مخصص لشكل بطاقة الاشتراك
  Widget _buildSubscriptionCard(Subscription sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.credit_card, color: Colors.deepOrange),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub.date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text("${sub.amount} SAR", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}