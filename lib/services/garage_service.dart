import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class GarageService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<Map<String, dynamic>> register({
    required String garage,
    required String mobile,
    required String email,
    required double latitude,
    required double longitude,
  }) async {
    final body = jsonEncode({
      "name":      garage,
      "mobile":    mobile,
      "latitude":  latitude,
      "longitude": longitude,
      if (email.trim().isNotEmpty) "email": email.trim(),
    });

    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.registerGarage),
      headers: await _headers(),
      body: body,
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      // Persist garage_id and branch_id immediately so the app
      // can start using them without requiring a re-login.
      final rawGarageId = decoded['garage_id'];
      final rawBranchId = decoded['branch_id'];

      if (rawGarageId != null) {
        await saveGarageId(rawGarageId is int
            ? rawGarageId
            : int.parse(rawGarageId.toString()));
      }
      if (rawBranchId != null) {
        await saveBranchId(rawBranchId is int
            ? rawBranchId
            : int.parse(rawBranchId.toString()));
      }
    }

    return {'status': response.statusCode, 'body': decoded};
  }
}