import 'dart:convert';
import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class ManageJobService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<List<Map<String, dynamic>>> fetchManageList() async {
    final branchId = await getBranchId();
    final garageId = await getGarageId();
    final params = <String, String>{};
    if (branchId != null)
      params['branch_id'] = branchId.toString();
    else if (garageId != null)
      params['garage_id'] = garageId.toString();

    final uri = Uri.parse(
      baseUrl + ApiEndpoints.manageJobs,
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(res.body) as Map)['jobs'] ?? [],
    );
  }

  Future<Map<String, dynamic>> fetchDetail(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<String> updateStatus(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({"action": "update_status"}),
    );
    _check(res);
    return (jsonDecode(res.body) as Map)['new_status'] as String;
  }

  Future<void> deleteJobCard(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.delete(uri, headers: await _headers());
    _check(res);
  }

  /// Search labour — passes garage_id and vehicle_model_id so the API
  /// can return the suggested price for this specific context.
  Future<List<Map<String, dynamic>>> searchLabour(
    String q, {
    int? garageId,
    int? vehicleModelId,
  }) async {
    final params = <String, String>{'q': q};
    if (garageId != null) params['garage_id'] = garageId.toString();
    if (vehicleModelId != null)
      params['vehicle_model_id'] = vehicleModelId.toString();

    final uri = Uri.parse(
      baseUrl + ApiEndpoints.labourSearch,
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    _check(res);
    return List<Map<String, dynamic>>.from(
      (jsonDecode(res.body) as Map)['labour'] ?? [],
    );
  }

  Future<Map<String, dynamic>> addLabour({
    required int jobcardId,
    int? labourId,
    String? labourName,
    required String amount,
    int? complaintId,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardLabour(jobcardId));
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        if (labourId != null) 'labour_id': labourId,
        if (labourName != null) 'labour_name': labourName,
        'amount': amount,
        if (complaintId != null) 'complaint_id': complaintId,
      }),
    );
    _check(res);
    return (jsonDecode(res.body) as Map)['labour_service']
        as Map<String, dynamic>;
  }

  Future<void> removeLabour({
    required int jobcardId,
    required int labourServiceId,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardLabour(jobcardId));
    final req = http.Request('DELETE', uri);
    req.headers.addAll(await _headers());
    req.body = jsonEncode({'labour_service_id': labourServiceId});
    final streamed = await req.send();
    _check(await http.Response.fromStream(streamed));
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final b = jsonDecode(res.body);
        if (b is Map && b['message'] != null) msg = b['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
