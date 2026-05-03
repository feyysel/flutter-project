import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadDriverDocument(File file, String userId) async {
    final ref = _storage.ref().child("driver_docs/$userId.jpg");

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }
}