import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {

    await _db
        .collection("users")
        .doc(user.userId)
        .set(user.toFirestore());

  }

  Future<UserModel?> getUser(String uid) async {

    final doc = await _db
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);

  }

  Future<void> updateBalance(String uid, double balance) async {

    await _db
        .collection("users")
        .doc(uid)
        .update({

      "total_balance": balance,
      "updated_at": FieldValue.serverTimestamp()

    });

  }

}