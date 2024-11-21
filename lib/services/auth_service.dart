Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      // Simpan token dan role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);

      return {
        'success': true,
        'role': data['role'],
        'message': data['message']
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Login gagal'
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Terjadi kesalahan: $e'
    };
  }
} 