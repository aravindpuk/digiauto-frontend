import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UsedSpareService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiEndpoints.customerUsedSpareRequests),
      headers: await _headers(),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Could not load your spare requests.');
    }
    final items = decoded is Map ? decoded['orders'] : null;
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createRequest({
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleYear,
    required String spareName,
    required List<XFile> images,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(baseUrl + ApiEndpoints.customerUsedSpareRequests),
          )
          ..headers.addAll(await _headers())
          ..fields.addAll({
            'vehicle_make': vehicleMake.trim(),
            'vehicle_model': vehicleModel.trim(),
            'vehicle_year': vehicleYear.trim(),
            'spare_name': spareName.trim(),
          });
    for (final image in images) {
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('images', bytes, filename: image.name),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Could not submit your spare request.');
    }
    return Map<String, dynamic>.from(decoded as Map);
  }
}
