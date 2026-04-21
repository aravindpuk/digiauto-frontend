import 'dart:convert';

import 'package:digiauto/utils/base_url.dart';

import 'package:http/http.dart' as http;
import '../utils//api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String pin,
  }) async {
    // Simulate a network call
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.login),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"mobile": mobile, "pin": pin}),
    );

    return {'status': response.statusCode, 'body': jsonDecode(response.body)};
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String pin,
    required String role,
  }) async {
    // Simulate a network call
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.registeruser),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "mobile": mobile,
        "pin": pin,
        "role": role,
      }),
    );

    return {'status': response.statusCode, 'body': jsonDecode(response.body)};
  }

  
}
