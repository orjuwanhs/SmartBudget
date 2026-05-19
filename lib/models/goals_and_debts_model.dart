import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {

  final String? id;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  SavingsGoalModel({
    this.id,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.createdAt,
    this.updatedAt,
  });

  factory SavingsGoalModel.fromFirestore(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SavingsGoalModel(

      id: doc.id,
      goalName: data['goal_name'] ?? '',
      targetAmount: (data['target_amount'] ?? 0).toDouble(),
      currentAmount: (data['current_amount'] ?? 0).toDouble(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),

    );

  }

  Map<String, dynamic> toFirestore() {

    return {

      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,

      'deadline': deadline != null
          ? Timestamp.fromDate(deadline!)
          : null,

      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),

    };

  }

}