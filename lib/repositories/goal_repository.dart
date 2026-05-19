import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goals_and_debts_model.dart';

class GoalRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createGoal(
      String uid,
      SavingsGoalModel goal
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("goals")
        .add(goal.toFirestore());

  }

  Stream<List<SavingsGoalModel>> getGoals(String uid) {

    return _db
        .collection("users")
        .doc(uid)
        .collection("goals")
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SavingsGoalModel.fromFirestore(doc))
        .toList());

  }

}