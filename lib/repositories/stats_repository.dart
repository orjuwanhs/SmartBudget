import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_stats_model.dart';

class StatsRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createMonth(
      String uid,
      String monthId,
      MonthlyStatsModel stats
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("stats")
        .doc(monthId)
        .set(stats.toFirestore());

  }

  Future<MonthlyStatsModel?> getMonthStats(
      String uid,
      String monthId
      ) async {

    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("stats")
        .doc(monthId)
        .get();

    if (!doc.exists) return null;

    return MonthlyStatsModel.fromFirestore(doc);

  }

}