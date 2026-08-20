import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  static UserModel? currentUser;

  static final SupabaseClient _client = Supabase.instance.client;

  static String? get currentUserId => _client.auth.currentUser?.id;

  static String _phoneToEmail(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return '$cleaned@driveon.local';
  }

  static Future<String> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      if (name.trim().isEmpty ||
          phone.trim().isEmpty ||
          password.trim().isEmpty) {
        return "All fields are required";
      }

      if (password.length < 8) {
        return "Password must be at least 8 characters";
      }

      final email = _phoneToEmail(phone.trim());

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
        },
      );

      if (response.user == null) {
        return "Registration failed";
      }

      // The database trigger auto-creates the profile row.
      // Update it to set role and other fields the trigger doesn't handle.
      await _client.from('profiles').update({
        'name': name.trim(),
        'phone': phone.trim(),
        'role': role,
        'is_verified': false,
        'verification_status': 'none',
        'is_online': false,
      }).eq('id', response.user!.id);

      return "success";
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        return "User already exists";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<dynamic> login({
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      if (phone.trim().isEmpty || password.trim().isEmpty) {
        return "All fields are required";
      }

      final email = _phoneToEmail(phone.trim());

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return "Login failed";
      }

      final doc = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (doc == null) {
        return "User not found";
      }

      if (doc['role'] != role) {
        return "Invalid role selected";
      }

      currentUser = UserModel.fromMap(doc);

      return currentUser;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await _client.from('profiles').select().eq('id', uid).maybeSingle();
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', uid);
  }
}
