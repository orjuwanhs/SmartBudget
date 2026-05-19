import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_controller.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. استدعاء الكنترولر للوصول للرسائل ووظيفة الإرسال
    final AIController controller = Get.find<AIController>();
    final TextEditingController textController = TextEditingController(); //نستخدمه لمسح النص من مربع الكتابة فور الضغط على إرسال

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("AI Financial Advisor", style: TextStyle(fontWeight:
        FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF103667),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 2. منطقة عرض الرسائل (تتحدث تلقائياً بفضل Obx)
          Expanded(
            child: Obx(() => ListView.builder( //تشغل معظم الشاشة. هي قائمة تعرض الرسائل واحدة تلو الأخرى
              padding: const EdgeInsets.all(15),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                var msg = controller.messages[index];
                bool isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text'] ?? "", isUser);
              },
            )),
          ),

          // 3. مؤشر التحميل (يظهر فقط عندما يفكر الـ AI)
          Obx(() => controller.isLoading.value
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(backgroundColor: Colors.transparent,
                color: Color(0xFF103667)),
          )
              : const SizedBox()),

          // 4. حقل إدخال الرسالة
          _buildInputSection(controller, textController),
        ],
      ),
    );
  }

  // دالة بناء فقاعة الدردشة
  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF103667) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  // دالة بناء منطقة الكتابة
  Widget _buildInputSection(AIController controller, TextEditingController textController) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: "Type your financial question...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF103667),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  controller.sendMessage(textController.text);
                  textController.clear(); // مسح النص بعد الإرسال لتجهيز الحقل للرسالة القادمة
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}