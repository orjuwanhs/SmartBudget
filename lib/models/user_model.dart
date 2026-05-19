import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? userId;
  final String fullName;
  final String email;
  final String phone;
  final String currency;
  final String? profilePic; // مسموح أن يكون null
  final String role;
  final double totalBalance;

  UserModel({
    this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.currency = 'SAR',
    this.profilePic, // لا نضع required هنا
    this.role = 'user',
    this.totalBalance = 0.0,
  });

  // --- إضافة دالة fromMap المطلوبة للكنترولر ---
  // هذه الدالة تحل مشكلة "The method 'fromMap' isn't defined"
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['uid'] ?? map['userId'], // دعم المسميين لضمان التوافق
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      currency: map['currency'] ?? 'SAR',
      profilePic: map['profile_pic'] ?? map['profilePic'],
      role: map['role'] ?? 'user',
      totalBalance: (map['total_balance'] ?? map['totalBalance'] ?? 0.0).toDouble(),
    );
  }

  // من Firestore إلى Flutter (استرجاع البيانات)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // استخدام Map? للتعامل مع احتمالية كون الوثيقة فارغة
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    return UserModel(
      userId: doc.id,
      fullName: data?['full_name'] ?? '',
      email: data?['email'] ?? '',
      phone: data?['phone'] ?? '',
      currency: data?['currency'] ?? 'SAR',
      // الحل هنا: لا نستخدم ?? '' للصورة، نتركها تأخذ null بسلام
      profilePic: data?['profile_pic'],
      role: data?['role'] ?? 'user',
      // تحويل آمن للرقم لتجنب خطأ Double vs Int
      totalBalance: (data?['total_balance'] ?? 0.0).toDouble(),
    );
  }

  // من Flutter إلى Firestore (حفظ البيانات)
  Map<String, dynamic> toFirestore() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'currency': currency,
      // سيتم حفظ القيمة كـ null في Firestore كما في صورتك
      'profile_pic': profilePic,
      'role': role,
      'total_balance': totalBalance,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // دالة toMap إضافية لضمان عمل كافة أجزاء الكنترولر
  Map<String, dynamic> toMap() => toFirestore();
}