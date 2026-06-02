import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AuthService {
  final String _baseUrl = "https://izerobase.com/staffix";

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      String deviceName =
          kIsWeb ? 'web_browser' : (Platform.isAndroid ? 'android' : 'ios');

      final response = await http
          .post(
            Uri.parse("$_baseUrl/login"),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: jsonEncode({
              'email': email,
              'password': password,
              'device_name': deviceName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        final String token = data['access_token'];
        final Map<String, dynamic> user = data['user'];

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user));

        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal masuk'};
    } catch (e) {
      debugPrint("ERROR KONEKSI: $e"); // Cek pesan ini di terminal VS Code
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  Future<Map<String, dynamic>?> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString('user');
    final String? token = prefs.getString('token');
    if (token != null && userStr != null) return jsonDecode(userStr);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      await http.post(
        Uri.parse("$_baseUrl/logout"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
    await prefs.clear();
  }
}
