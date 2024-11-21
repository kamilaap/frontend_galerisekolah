import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactService {
  static Future<bool> submitContact(String name, String email, String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/contact'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting contact: $e');
      return false;
    }
  }
} 