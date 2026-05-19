import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCategory(
      String uid,
      CategoryModel category
      ) async {

    await _db
        .collection("users")
        .doc(uid)
        .collection("categories")
        .add(category.toFirestore());

  }

  Stream<List<CategoryModel>> getCategories(String uid) {

    return _db
        .collection("users")
        .doc(uid)
        .collection("categories")
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList());

  }

}