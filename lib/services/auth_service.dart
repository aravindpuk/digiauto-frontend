import 'dart:convert';

import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;
import '../utils//api_endpoints.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String pin,
  }) async {
    // Simulate a network call
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.login),
      body: jsonEncode({'mobile': mobile, 'pin': pin}),
    );

    return {'status': response.statusCode, 'body': jsonDecode(response.body)};
  }
}
