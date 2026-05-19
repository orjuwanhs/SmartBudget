import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// Category
  Future<void> addCategory(Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("categories")
        .add(data);
  }

  /// Budget
  Future<void> addBudget(Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("budgets")
        .add(data);
  }

  /// Notification
  Future<void> addNotification(Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .add(data);
  }

  /// Activity Log
  Future<void> addActivity(Map<String, dynamic> data) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("activity_logs")
        .add(data);
  }

}