import '../models/user_model.dart';

class AuthService {
  static UserModel? currentUser;

  // Temporary in-memory storage
  static List<Map<String, dynamic>> users = [];

  // ================= REGISTER =================
  static Future<String> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(Duration(seconds: 1));

    // 1. empty validation
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      return "All fields are required";
    }

    // 2. password rule (>= 8)
    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }

    // 3. prevent duplicate (same email for both roles)
    bool userExists = users.any(
      (user) => user["email"].toString().toLowerCase() == email.toLowerCase(),
    );

    if (userExists) {
      return "User already exists";
    }

    // 4. save user
    users.add({
      "name": name.trim(),
      "email": email.trim(),
      "password": password,
      "role": role,
    });

    return "success";
  }

  // ================= LOGIN =================
  static Future<dynamic> login({
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(Duration(seconds: 1));

    // 1. empty validation
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return "All fields are required";
    }

    // 2. find user by email
    Map<String, dynamic>? user;

    for (var u in users) {
      if (u["email"].toString().toLowerCase() == email.toLowerCase()) {
        user = u;
        break;
      }
    }

    // 3. user not found
    if (user == null) {
      return "User not found";
    }

    // 4. wrong password
    if (user["password"] != password) {
      return "Wrong password";
    }

    // 5. wrong role (driver/passenger)
    if (user["role"] != role) {
      return "Invalid role selected";
    }

    // ✅ 6. success
    currentUser = UserModel(
      name: user["name"],
      email: user["email"],
      role: user["role"],
    );

    return currentUser;
  }
}
