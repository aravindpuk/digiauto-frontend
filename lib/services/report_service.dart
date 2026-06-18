import 'dart:convert';

import 'package:digiauto/models/report_data.dart';
import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class ReportService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<GarageReport> fetchReport({
    required String period, // today | week | month | custom
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final branchId = await getBranchId();
    final garageId = await getGarageId();

    final params = <String, String>{'period': period};
    if (branchId != null) {
      params['branch_id'] = branchId.toString();
    } else if (garageId != null) {
      params['garage_id'] = garageId.toString();
    }
    if (period == 'custom' && startDate != null && endDate != null) {
      params['start_date'] = _formatDate(startDate);
      params['end_date'] = _formatDate(endDate);
    }

    final uri = Uri.parse(baseUrl + ApiEndpoints.jobcardReports)
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load report (${res.statusCode})');
    }
    return GarageReport.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}