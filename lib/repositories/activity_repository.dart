import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log_model.dart';

class ActivityRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addLog(
      String uid,
      ActivityLogModel log
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("activity_logs")
        .add(log.toFirestore());

  }

  Stream<List<ActivityLogModel>> getLogs(String uid) {

    return _db
        .collection("users")
        .doc(uid)
        .collection("activity_logs")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ActivityLogModel.fromFirestore(doc))
        .toList());

  }

}