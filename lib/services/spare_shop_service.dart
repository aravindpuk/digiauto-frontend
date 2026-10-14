import 'dart:convert';

import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SpareShopService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _decode(http.Response response) async {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(
        message ?? 'The spare shop request could not be completed.',
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.registerSpareShop),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );
    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body) as Map<String, dynamic>,
    };
  }

  Future<List<Map<String, dynamic>>> fetchInventory({String query = ''}) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.spareShopInventory).replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
    );
    final response = await http.get(uri, headers: await _headers());
    final data = await _decode(response);
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> saveInventory({
    int? itemId,
    required int vehicleModelId,
    required String vehicleYear,
    required String spareName,
    required String mrp,
    required List<XFile> images,
    List<int> removeImageIds = const [],
  }) async {
    final uri = Uri.parse(
      itemId == null
          ? baseUrl + ApiEndpoints.spareShopInventory
          : baseUrl + ApiEndpoints.spareShopInventoryItem(itemId),
    );
    final request = http.MultipartRequest(itemId == null ? 'POST' : 'PUT', uri)
      ..headers.addAll(await _headers())
      ..fields.addAll({
        'vehicle_model_id': vehicleModelId.toString(),
        'vehicle_year': vehicleYear.trim(),
        'spare_name': spareName.trim(),
        'mrp': mrp.trim(),
        if (removeImageIds.isNotEmpty)
          'remove_image_ids': removeImageIds.join(','),
      });
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(await _decode(response) as Map);
  }

  Future<void> removeInventoryItem(int itemId) async {
    final response = await http.delete(
      Uri.parse(baseUrl + ApiEndpoints.spareShopInventoryItem(itemId)),
      headers: await _headers(),
    );
    await _decode(response);
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiEndpoints.spareShopOrders),
      headers: await _headers(),
    );
    final data = await _decode(response);
    final orders = data is Map ? data['orders'] : null;
    if (orders is! List) return const [];
    return orders
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String action,
    String note = '',
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.spareShopOrder(orderId)),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'action': action, 'note': note}),
    );
    return Map<String, dynamic>.from(await _decode(response) as Map);
  }

  Future<Map<String, dynamic>> fetchDigiStaffOrders() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiEndpoints.digiStaffSpareOrders),
      headers: await _headers(),
    );
    return Map<String, dynamic>.from(await _decode(response) as Map);
  }

  Future<void> forwardOrder({
    required int requestId,
    required int shopId,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.forwardSpareOrder(requestId)),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'shop_id': shopId}),
    );
    await _decode(response);
  }
}
