import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend URL configuration:
  // - Android emulator: 10.0.2.2 (special alias to host machine's localhost)
  // - iOS simulator: localhost
  // - Real device: your computer's actual IP address (e.g., 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  /// Get authentication token from storage
  static Future<String?> _getToken({String tokenKey = 'auth_token'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// Build headers with optional authentication
  static Future<Map<String, String>> _buildHeaders({
    bool includeAuth = false,
    String tokenKey = 'auth_token',
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken(tokenKey: tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
    String tokenKey = 'auth_token',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(
        includeAuth: requiresAuth,
        tokenKey: tokenKey,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
    String tokenKey = 'auth_token',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(
        includeAuth: requiresAuth,
        tokenKey: tokenKey,
      );

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
    String tokenKey = 'auth_token',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(
        includeAuth: requiresAuth,
        tokenKey: tokenKey,
      );

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    String tokenKey = 'auth_token',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(
        includeAuth: requiresAuth,
        tokenKey: tokenKey,
      );

      final response = await http.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
    String tokenKey = 'auth_token',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _buildHeaders(
        includeAuth: requiresAuth,
        tokenKey: tokenKey,
      );

      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }
}
