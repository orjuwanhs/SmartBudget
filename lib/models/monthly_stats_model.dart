import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyStatsModel {

  final String? id;

  final double totalIncome;
  final double totalExpense;
  final double balance;

  final DateTime? updatedAt;

  MonthlyStatsModel({
    this.id,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.balance = 0,
    this.updatedAt,
  });

  factory MonthlyStatsModel.fromFirestore(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MonthlyStatsModel(

      id: doc.id,
      totalIncome: (data['total_income'] ?? 0).toDouble(),
      totalExpense: (data['total_expense'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),

    );

  }

  Map<String, dynamic> toFirestore() {

    return {

      "total_income": totalIncome,
      "total_expense": totalExpense,
      "balance": balance,
      "updated_at": FieldValue.serverTimestamp(),

    };

  }

}