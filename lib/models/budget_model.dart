import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String categoryId;
  final double limitAmount;
  final double spentAmount;
  final String month;

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.limitAmount,
    this.spentAmount = 0,
    required this.month,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return BudgetModel(
      id: doc.id,
      categoryId: data['category_id'] ?? '',
      limitAmount: (data['limit_amount'] ?? 0).toDouble(),
      spentAmount: (data['spent_amount'] ?? 0).toDouble(),
      month: data['month'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category_id': categoryId,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
      'month': month,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}