import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createBudget(
      String uid,
      BudgetModel budget
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("budgets")
        .add(budget.toFirestore());

  }

  Stream<List<BudgetModel>> getBudgets(String uid) {

    return _db
        .collection("users")
        .doc(uid)
        .collection("budgets")
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BudgetModel.fromFirestore(doc))
        .toList());

  }

}