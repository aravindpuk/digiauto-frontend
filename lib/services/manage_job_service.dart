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

  // ── Fetch brief list for manage panel ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchManageList() async {
    final branchId = await getBranchId();
    final garageId = await getGarageId();
    final params   = <String, String>{};
    if (branchId != null) params['branch_id'] = branchId.toString();
    else if (garageId != null) params['garage_id'] = garageId.toString();

    final uri = Uri.parse(baseUrl + ApiEndpoints.manageJobs)
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['jobs'] ?? []);
  }

  // ── Full detail of one jobcard ─────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchDetail(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Advance status ────────────────────────────────────────────────────────
  Future<String> updateStatus(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({"action": "update_status"}),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['new_status'] as String;
  }

  // ── Delete jobcard ────────────────────────────────────────────────────────
  Future<void> deleteJobCard(int jobcardId) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(jobcardId));
    final res = await http.delete(uri, headers: await _headers());
    _checkStatus(res);
  }

  // ── Search labour ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchLabour(String q) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.labourSearch)
        .replace(queryParameters: {'q': q});
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['labour'] ?? []);
  }

  // ── Add labour ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addLabour({
    required int jobcardId,
    int? labourId,
    String? labourName,
    required String amount,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardLabour(jobcardId));
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        if (labourId != null) 'labour_id': labourId,
        if (labourName != null) 'labour_name': labourName,
        'amount': amount,
      }),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['labour_service'] as Map<String, dynamic>;
  }

  // ── Remove labour ─────────────────────────────────────────────────────────
  Future<void> removeLabour({
    required int jobcardId,
    required int labourServiceId,
  }) async {
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardLabour(jobcardId));
    final req = http.Request('DELETE', uri);
    req.headers.addAll(await _headers());
    req.body = jsonEncode({'labour_service_id': labourServiceId});
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final b = jsonDecode(res.body);
        if (b is Map && b['message'] != null) msg = b['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }
}