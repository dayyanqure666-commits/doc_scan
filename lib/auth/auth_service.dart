import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'session_manager.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SessionManager _sessionManager = SessionManager();
  
  // A local preference key to store simulated registered emails
  static const _keyRegisteredEmails = 'mock_auth_registered_emails';

  /// Authenticate a user with email and password.
  /// Simulates a network call and returns a UserModel.
  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Invalid email address format.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // Check if the user is registered in our local mock database
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getStringList(_keyRegisteredEmails) ?? [];

    if (!registered.contains(normalizedEmail)) {
      throw Exception('User account not found. Please register first.');
    }

    // Generate a mock JWT token (header.payload.signature)
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': normalizedEmail.hashCode.toString(),
      'email': normalizedEmail,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    })));
    final mockToken = '$header.$payload.mock_signature';

    final user = UserModel(
      id: normalizedEmail.hashCode.toString(),
      email: normalizedEmail,
      token: mockToken,
    );

    // Save login session securely
    await _sessionManager.saveSession(user);
    return user;

    /*
    // =========================================================================
    // Firebase Auth REST API implementation example:
    // =========================================================================
    // import 'package:http/http.dart' as http;
    //
    // const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
    // final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseApiKey');
    //
    // final response = await http.post(
    //   url,
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'email': email,
    //     'password': password,
    //     'returnSecureToken': true,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   final user = UserModel(
    //     id: data['localId'],
    //     email: data['email'],
    //     token: data['idToken'], // JWT Token
    //   );
    //   await _sessionManager.saveSession(user);
    //   return user;
    // } else {
    //   final errorData = jsonDecode(response.body);
    //   throw Exception(errorData['error']['message'] ?? 'Failed to authenticate');
    // }
    */
  }

  /// Register a new user with email and password.
  /// Simulates a network call and registers the user locally.
  Future<UserModel> register(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Invalid email address format.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getStringList(_keyRegisteredEmails) ?? [];

    if (registered.contains(normalizedEmail)) {
      throw Exception('Email already registered. Please log in.');
    }

    // Add to registered list
    registered.add(normalizedEmail);
    await prefs.setStringList(_keyRegisteredEmails, registered);

    // Auto-login after registration by generating token
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': normalizedEmail.hashCode.toString(),
      'email': normalizedEmail,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    })));
    final mockToken = '$header.$payload.mock_signature';

    final user = UserModel(
      id: normalizedEmail.hashCode.toString(),
      email: normalizedEmail,
      token: mockToken,
    );

    // Save session securely
    await _sessionManager.saveSession(user);
    return user;

    /*
    // =========================================================================
    // Firebase Auth REST API registration example:
    // =========================================================================
    // import 'package:http/http.dart' as http;
    //
    // const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
    // final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseApiKey');
    //
    // final response = await http.post(
    //   url,
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'email': email,
    //     'password': password,
    //     'returnSecureToken': true,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   final user = UserModel(
    //     id: data['localId'],
    //     email: data['email'],
    //     token: data['idToken'],
    //   );
    //   await _sessionManager.saveSession(user);
    //   return user;
    // } else {
    //   final errorData = jsonDecode(response.body);
    //   throw Exception(errorData['error']['message'] ?? 'Failed to register');
    // }
    */
  }

  /// Sign out the current user, clearing the persisted secure session.
  Future<void> logout() async {
    await _sessionManager.clearSession();
  }

  /// Retrieve the current logged-in user, if any.
  Future<UserModel?> getCurrentUser() async {
    return await _sessionManager.getSession();
  }

  /// Retrieve the token of the current active session, if any.
  Future<String?> getToken() async {
    final user = await _sessionManager.getSession();
    return user?.token;
  }
}
