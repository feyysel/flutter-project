import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String> uploadDriverDocument(File file, String userId, {String? fileName}) async {
    final name = fileName ?? 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final path = 'driver_docs/$userId/$name';

    await _client.storage.from('driver-docs').upload(path, file);

    final url = _client.storage.from('driver-docs').getPublicUrl(path);

    return url;
  }

  static Future<String> uploadProfileImage(File file, String userId) async {
    final path = 'profiles/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}';

    await _client.storage.from('profile-images').upload(path, file);

    final url = _client.storage.from('profile-images').getPublicUrl(path);

    return url;
  }
}
