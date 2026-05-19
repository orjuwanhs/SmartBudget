import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../screen/subscriptions_screen.dart';

class SubscriptionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var mySubscriptions = <Subscription>[].obs;
  var isLoading = false.obs;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    listenToSubscriptions();
  }

  void listenToSubscriptions() {
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .snapshots()
        .listen((snapshot) {
      mySubscriptions.assignAll(snapshot.docs.map((doc) {
        var data = doc.data();
        return Subscription(
          name: data['name'],
          amount: (data['amount'] ?? 0.0).toDouble(),
          date: data['date'],
        );
      }).toList());
    });
  }

  Future<void> addSubscriptionToDB(String name, double amount, String date) async {
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .add({
        'name': name,
        'amount': amount,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Get.snackbar("Success", "Subscription saved to cloud!");
    } catch (e) {
      Get.snackbar("Error", "Failed to save: $e");
    }
  }
}