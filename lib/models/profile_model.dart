import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String? id;

  final String fullName;
  final String email;
  final String phone;

  final String currency;
  final String? profilePic;

  final double totalBalance;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.currency = "SAR",
    this.profilePic,
    this.totalBalance = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProfileModel(
      id: doc.id,
      fullName: data['full_name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      currency: data['currency'] ?? 'SAR',
      profilePic: data['profile_pic'],
      totalBalance: (data['total_balance'] ?? 0).toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "currency": currency,
      "profile_pic": profilePic,
      "total_balance": totalBalance,
      "created_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    };
  }
}