import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartbudget/view/auth/login_screen.dart';
import '../thems/app_theme.dart';

class SignUpController extends GetxController {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  /// ==============================
  /// SIGN UP
  /// ==============================

  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phone,
  }) async {

    if (email.trim().isEmpty ||
        password.trim().isEmpty ||
        fullName.trim().isEmpty ||
        phone.trim().isEmpty) {

      AppStyles.showErrorSnackbar(
        "Missing Info",
        "All fields are required.",
      );
      return;
    }

    if (!GetUtils.isEmail(email.trim())) {

      AppStyles.showErrorSnackbar(
        "Invalid Email",
        "Please enter a valid email.",
      );
      return;
    }

    if (password != confirmPassword) {

      AppStyles.showErrorSnackbar(
        "Mismatch",
        "Passwords do not match.",
      );
      return;
    }

    try {

      isLoading.value = true;

      /// إنشاء المستخدم في FirebaseAuth

      UserCredential res =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = res.user!.uid;

      /// إنشاء بيانات المستخدم في Firestore

      await createUserData(
        uid,
        fullName.trim(),
        email.trim(),
        phone.trim(),
      );

      /// نجاح

      AppStyles.showSuccessSnackbar(
        "Success",
        "Account created successfully!",
      );

      Future.delayed(
        const Duration(milliseconds: 1200),
            () => Get.offAll(() => LoginPage()),
      );

    }

    on FirebaseAuthException catch (e) {

      String message = "An error occurred";

      if (e.code == 'email-already-in-use') {
        message = "This email is already in use.";
      }

      else if (e.code == 'weak-password') {
        message = "The password is too weak.";
      }

      AppStyles.showErrorSnackbar(
        "Registration Failed",
        message,
      );

    }

    catch (e) {

      AppStyles.showErrorSnackbar(
        "System Error",
        "Something went wrong.",
      );

      print("Error Log: $e");

    }

    finally {

      isLoading.value = false;

    }

  }

  /// ==============================
  /// CREATE USER DATA
  /// ==============================

  Future<void> createUserData(
      String uid,
      String fullName,
      String email,
      String phone,
      ) async {

    WriteBatch batch = _db.batch();

    DocumentReference userRef =
    _db.collection("users").doc(uid);

    /// USER DOCUMENT

    batch.set(userRef, {

      "full_name": fullName,
      "email": email,
      "phone": phone,
      "currency": "SAR",
      "role": "user",
      "total_balance": 0,

      "created_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),

    });

    /// MONTHLY STATS

    String monthId =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    batch.set(
      userRef.collection("stats").doc(monthId),
      {

        "total_income": 0,
        "total_expense": 0,
        "balance": 0,

        "updated_at": FieldValue.serverTimestamp(),

      },
    );

    /// DEFAULT CATEGORIES

    List defaultCategories = [

      {
        "name": "Food",
        "icon": 0xe56c,
        "color": 0xFFFF7043,
        "type": "expense"
      },

      {
        "name": "Transport",
        "icon": 0xe531,
        "color": 0xFF42A5F5,
        "type": "expense"
      },

      {
        "name": "Shopping",
        "icon": 0xe59c,
        "color": 0xFFAB47BC,
        "type": "expense"
      },

      {
        "name": "Bills",
        "icon": 0xe8c5,
        "color": 0xFFEF5350,
        "type": "expense"
      },

      {
        "name": "Salary",
        "icon": 0xe263,
        "color": 0xFF66BB6A,
        "type": "income"
      },
      {"name": "Drinks", "icon": "fastfood", "color": "0xFF4CAF50", "type": "expense"},
      {"name": "Health", "icon": "medical_services", "color": "0xFFE91E63", "type": "expense"},


    ];

    for (var cat in defaultCategories) {

      DocumentReference catRef =
      userRef.collection("categories").doc();

      batch.set(catRef, {
        "name": cat["name"],
        "icon": cat["icon"],
        "color": cat["color"],
        "type": cat["type"],
        "is_system": true, // مهم
        "created_at": FieldValue.serverTimestamp(),
      });

    }

    /// ACTIVITY LOG

    DocumentReference activityRef =
    userRef.collection("activity_logs").doc();

    batch.set(activityRef, {

      "title": "Account Created",
      "description": "User registered in the system",
      "type": "system",

      "timestamp": FieldValue.serverTimestamp(),

    });

    /// تنفيذ كل العمليات

    await batch.commit();

  }

}