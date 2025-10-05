import 'package:movie_booking_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  /// Register a new user
  /// Returns user data and token on success
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response['success'] == true && response['data'] != null) {
        // Save token and user info
        final token = response['data']['token'] as String;
        final user = response['data']['user'] as Map<String, dynamic>;

        await _saveAuthData(token, user);

        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /// Login an existing user
  /// Returns user data and token on success
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] == true && response['data'] != null) {
        // Save token and user info
        final token = response['data']['token'] as String;
        final user = response['data']['user'] as Map<String, dynamic>;

        await _saveAuthData(token, user);

        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Save authentication data to local storage
  static Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, user['id'] as int);
    await prefs.setString(_userEmailKey, user['email'] as String);
    await prefs.setString(_userNameKey, user['name'] as String);
  }

  /// Get the stored authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);

    if (userId != null && email != null && name != null) {
      return {
        'id': userId,
        'email': email,
        'name': name,
      };
    }
    return null;
  }

  /// Logout user - clear all stored data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }
}
