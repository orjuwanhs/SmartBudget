import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String? id;
  final String title;
  final String description;
  final String type;
  final double amount;

  final String? referenceId;
  final String entityType;

  final DateTime? timestamp;

  ActivityLogModel({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    this.amount = 0,
    this.referenceId,
    required this.entityType,
    this.timestamp,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ActivityLogModel(

      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      referenceId: data['reference_id'],
      entityType: data['entity_type'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),

    );

  }

  Map<String, dynamic> toFirestore() {

    return {

      "title": title,
      "description": description,
      "type": type,
      "amount": amount,
      "reference_id": referenceId,
      "entity_type": entityType,
      "timestamp": FieldValue.serverTimestamp(),

    };

  }
}