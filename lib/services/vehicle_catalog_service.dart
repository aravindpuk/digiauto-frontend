import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class VehicleCatalogService {
  Future<List<Map<String, dynamic>>> fetchMakes() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiEndpoints.vehicleCatalog),
      headers: const {'Accept': 'application/json'},
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load vehicle makes and models.');
    }
    final makes = decoded is Map ? decoded['makes'] : null;
    if (makes is! List) return const [];
    return makes
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
