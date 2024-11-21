import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Attempting login to: $baseUrl/api/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save user data to SharedPreferences based on new response format
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        await prefs.setString('role', data['role'] ?? '');

        return {
          'success': true,
          'role': 'user',
          'message': 'Login berhasil'
        };
      }

      return {
        'success': false,
        'message': 'Email atau password salah'
      };

    } catch (e) {
      print('Error during login: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'user');
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}