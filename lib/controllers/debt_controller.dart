import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DebtController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? "";

  // جلب الديون من الفايربيس وتحويلها لقائمة
  Stream<List<Map<String, dynamic>>> get debtsStream {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('debts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // إضافة دين جديد
  Future<void> addDebt(String name, double amount, DateTime dueDate) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('debts').add({
      'name': name,
      'amount': amount,
      'dueDate': dueDate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // حذف دين
  Future<void> deleteDebt(String id) async {
    await _firestore.collection('users').doc(uid).collection('debts').doc(id).delete();
  }
}