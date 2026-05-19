import 'package:cloud_firestore/cloud_firestore.dart';
class TransactionModel {
  final String? id;
  final double amount;
  final String type;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? note;
  final double balanceBefore;
  final double balanceAfter;
  final double incomeAmount;
  final double expenseAmount;
  final DateTime timestamp;

  TransactionModel({
    this.id, required this.amount, required this.type,
    this.categoryId, this.categoryName, this.categoryIcon, this.categoryColor,
    this.note, required this.balanceBefore, required this.balanceAfter,
    required this.incomeAmount, required this.expenseAmount, required this.timestamp,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? "Expense",
      categoryId: data['category_id'], // مطابقة لصور Firestore
      categoryName: data['category_name'],
      categoryIcon: data['category_icon']?.toString(),
      categoryColor: data['category_color']?.toString(),
      note: data['note'] ?? "",
      balanceBefore: (data['balance_before'] ?? 0).toDouble(), // مطابقة لصور Firestore
      balanceAfter: (data['balance_after'] ?? 0).toDouble(),
      incomeAmount: (data['income_amount'] ?? 0).toDouble(),
      expenseAmount: (data['expense_amount'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "amount": amount,
      "type": type,
      "category_id": categoryId,
      "category_name": categoryName,
      "category_icon": categoryIcon,
      "category_color": categoryColor,
      "note": note,
      "balance_before": balanceBefore,
      "balance_after": balanceAfter,
      "income_amount": incomeAmount,
      "expense_amount": expenseAmount,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}