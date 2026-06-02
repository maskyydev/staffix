import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProfileService {
  final String baseUrl = 'https://izerobase.com/staffix/api';
  final String token = 'TARUH_BEARER_TOKEN_DISINI';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profil'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<bool> updateProfile({
    required Map<String, String> body,
    File? imageFile,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/profil/update'))
          ..headers.addAll(_headers)
          ..fields.addAll(body);

    if (imageFile != null) {
      request.files.add(
          await http.MultipartFile.fromPath('foto_profil', imageFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> updateCompany({
    required Map<String, String> body,
    File? logoFile,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/profil/update-perusahaan'))
      ..headers.addAll(_headers)
      ..fields.addAll(body);

    if (logoFile != null) {
      request.files.add(
          await http.MultipartFile.fromPath('logo_perusahaan', logoFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> updatePassword(
      String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profil/update-password'),
      headers: _headers,
      body: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.statusCode == 200;
  }
}
