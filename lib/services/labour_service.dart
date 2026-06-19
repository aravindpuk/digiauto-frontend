import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class LabourService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<List<Map<String, dynamic>>> searchLabour(String query) async {
    final garageId = await getGarageId();
    final params = {
      'q': query,
      if (garageId != null) 'garage_id': garageId.toString(),
    };
    final uri = Uri.parse(
      baseUrl + ApiEndpoints.labourSearch,
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    _check(response);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(response.body) as Map)['labour'] ?? [],
    );
  }

  Future<Map<String, dynamic>> createLabour({
    required String name,
    required String cost,
  }) async {
    final garageId = await getGarageId();
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.labourCreate),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'cost': cost,
        if (garageId != null) 'garage_id': garageId,
      }),
    );
    _check(response);
    return (jsonDecode(response.body) as Map)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLabour({
    required int labourId,
    required String name,
    required String cost,
  }) async {
    final garageId = await getGarageId();
    final response = await http.put(
      Uri.parse(baseUrl + ApiEndpoints.labourUpdate(labourId)),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'cost': cost,
        if (garageId != null) 'garage_id': garageId,
      }),
    );
    _check(response);
    return (jsonDecode(response.body) as Map)['data'] as Map<String, dynamic>;
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
