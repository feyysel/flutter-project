import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class AuthService {
  static UserModel? currentUser;

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= REGISTER =================
  static Future<String> register({
  required String name,
  required String email,
  required String password,
  required String role,
}) async {
  await Future.delayed(Duration(seconds: 1));

  try {
    // validation
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      return "All fields are required";
    }

    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }

    // create firebase user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // save to firestore
    await _db.collection("users").doc(cred.user!.uid).set({
      "name": name.trim(),
      "email": email.trim(),
      "role": role,
    });

    return "success";
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      return "User already exists";
    }

    return e.message ?? "Registration failed";
  } catch (e) {
    return e.toString();
  }
}

  // ================= LOGIN =================
  static Future<dynamic> login({
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(Duration(seconds: 1));

    try {
      // 1. empty validation
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return "All fields are required";
      }

      // 2. sign in with Firebase
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 3. get user from Firestore
      final doc = await _db.collection("users").doc(cred.user!.uid).get();

      if (!doc.exists) {
        return "User not found";
      }

      final user = doc.data()!;

      // 4. wrong role
      if (user["role"] != role) {
        return "Invalid role selected";
      }

      // 5. success
      currentUser = UserModel(
        name: user["name"],
        email: user["email"],
        role: user["role"],
      );

      return currentUser;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
  }
}
