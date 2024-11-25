import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/aplikasisekolah/backend_galerisekolah/public';
    } else {
      return 'http://10.0.2.2/aplikasisekolah/backend_galerisekolah/public';
    }
  }

  static Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token'
  };

  static Future<http.Response> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/$endpoint'),
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  static Future<http.Response> post(String endpoint, dynamic body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/$endpoint'),
        headers: headers,
        body: body,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }
} 