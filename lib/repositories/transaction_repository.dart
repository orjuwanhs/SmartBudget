import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTransaction(
      String uid,
      TransactionModel transaction
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .add(transaction.toFirestore());

  }

  Stream<List<TransactionModel>> getTransactions(String uid) {

    return _db
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());

  }

  Future<void> deleteTransaction(String uid, String id) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .doc(id)
        .delete();

  }

}