import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService()
      : _storage = const FlutterSecureStorage(
          webOptions: WebOptions(
            dbName: 'oouth_mobile',
            publicKey: 'oouth_mobile_key',
          ),
        );

  Future<void> saveUser(User user) async {
    try {
      final userJson = user.toJson();
      await _storage.write(key: 'user', value: jsonEncode(userJson));
      print('User saved to storage: ${user.email}'); // Debug
    } catch (e) {
      print('Error saving user: $e'); // Debug
      rethrow;
    }
  }

  Future<User?> getUser() async {
    try {
      final userStr = await _storage.read(key: 'user');
      if (userStr != null) {
        final userMap = jsonDecode(userStr) as Map<String, dynamic>;
        return User.fromJson(userMap, userMap['token'] as String);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e'); // Debug
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      await _storage.delete(key: 'user');
      print('User cleared from storage'); // Debug
    } catch (e) {
      print('Error clearing user: $e'); // Debug
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      return await _storage.containsKey(key: 'user');
    } catch (e) {
      print('Error checking login status: $e'); // Debug
      return false;
    }
  }
}
