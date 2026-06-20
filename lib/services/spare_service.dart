import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class SpareService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<List<Map<String, dynamic>>> searchSpares(String q) async {
    final uri = Uri.parse(
      baseUrl + ApiEndpoints.spareSearch,
    ).replace(queryParameters: {'q': q});
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(res.body) as Map)['spares'] ?? [],
    );
  }

  Future<Map<String, dynamic>> createSpare({
    required String partName,
    String partNumber = "",
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.spares);
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'partname': partName, 'partnumber': partNumber}),
    );
    _check(res);
    return (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSpare({
    required int spareId,
    required String partName,
    required String partNumber,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.spareUpdate(spareId));
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({'partname': partName, 'partnumber': partNumber}),
    );
    _check(res);
    return (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listStock(int branchId) async {
    final uri = Uri.parse(
      baseUrl + ApiEndpoints.spareList(branchId),
    ).replace(queryParameters: {'include_zero': '1'});
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
  }

  Future<Map<String, dynamic>> addStock({
    required int spareId,
    required int branchId,
    required int quantity,
    required String mrp,
    required String purchaseAmount,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.spareStockAdd);
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'spare_id': spareId,
        'branch_id': branchId,
        'quantity': quantity,
        'mrp': mrp,
        'purchase_amount': purchaseAmount,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStock({
    required int stockId,
    required int quantity,
    required String mrp,
    required String purchaseAmount,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.spareStockUpdate(stockId));
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'quantity': quantity,
        'mrp': mrp,
        'purchase_amount': purchaseAmount,
      }),
    );
    _check(res);
    return (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
