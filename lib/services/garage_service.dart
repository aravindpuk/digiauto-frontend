import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class GarageService {
  Future<String?> token = getToken();
  Future<Map<String, dynamic>> register({
    required String garage,
    required String mobile,
    required String email,
    required double latitude,
    required double longitude,
  }) async {
    final body = {
      "name": garage,
      "mobile": mobile,
      "latitude": latitude,
      "longitude": longitude,
    };

    if (email.isNotEmpty) {
      body["email"] = email;
    }

    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.registerGarage),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    // Returning mock garage details
    return {'status': response.statusCode};
  }
}
