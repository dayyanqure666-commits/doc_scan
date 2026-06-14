import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserToken = 'user_token';

  Future<void> saveSession(UserModel user) async {
    try {
      await _secureStorage.write(key: _keyUserId, value: user.id);
      await _secureStorage.write(key: _keyUserEmail, value: user.email);
      await _secureStorage.write(key: _keyUserToken, value: user.token);
    } catch (_) {
      // Fallback or log error
    }
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyUserEmail);
      await _secureStorage.delete(key: _keyUserToken);
    } catch (_) {
      // Handle exception
    }
  }

  Future<UserModel?> getSession() async {
    try {
      final id = await _secureStorage.read(key: _keyUserId);
      final email = await _secureStorage.read(key: _keyUserEmail);
      final token = await _secureStorage.read(key: _keyUserToken);

      if (id != null && email != null && token != null) {
        return UserModel(id: id, email: email, token: token);
      }
    } catch (_) {
      // Fail gracefully
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: _keyUserToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
