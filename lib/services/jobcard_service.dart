import 'dart:convert';

import 'package:digiauto/models/job_card.dart';
import 'package:digiauto/utils/api_endpoints.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/base_url.dart';
import 'package:http/http.dart' as http;

class JobcardService {
  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  // ─── Fetch Jobs ───────────────────────────────────────────────────────────

  Future<List<JobCard>> fetchJobs() async {
    final garageId = await getGarageId();
    final branchId = await getBranchId();

    // Build query params — prefer branch_id for precise filtering
    final params = <String, String>{};
    if (branchId != null) {
      params['branch_id'] = branchId.toString();
    } else if (garageId != null) {
      params['garage_id'] = garageId.toString();
    }

    final uri = Uri.parse(
      baseUrl + ApiEndpoints.jobCards,
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch jobs (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> items = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic>
              ? (decoded['jobcards'] ??
                    decoded['results'] ??
                    decoded['data'] ??
                    [])
              : []);

    return items
        .whereType<Map<String, dynamic>>()
        .map(JobCard.fromJson)
        .toList();
  }

  Future<JobCard> fetchJobDetail(String jobcardId) async {
    final id = int.tryParse(jobcardId);
    if (id == null) {
      throw Exception('Invalid job card id');
    }
    final uri = Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(id));
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch job details (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final jobcardData = decoded['jobcard'] ?? decoded;
      if (jobcardData is Map<String, dynamic>) {
        return JobCard.fromJson(jobcardData);
      }
    }
    throw Exception('Invalid job details response');
  }

  Future<JobCard> updateJobCard({
    required String jobcardId,
    required String vehicleNumber,
    required String customerName,
    required String mobile,
    required String place,
    required String vehicleModel,
    required String vehicleMake,
    required String year,
    required String chassisNumber,
    required String engineNumber,
    required String kilometer,
    required List<String> services,
  }) async {
    final id = int.tryParse(jobcardId);
    if (id == null) {
      throw Exception('Invalid job card id');
    }

    final response = await http.patch(
      Uri.parse(baseUrl + ApiEndpoints.jobCardDetail(id)),
      headers: await _headers(),
      body: jsonEncode({
        'action': 'edit',
        'vehicle_number': vehicleNumber.trim().toUpperCase(),
        'customer_name': customerName.trim(),
        'mobile': mobile.trim(),
        'place': place.trim(),
        'vehicle_model': vehicleModel.trim(),
        'vehicle_make': vehicleMake.trim(),
        'year': year.trim(),
        'chassis_number': chassisNumber.trim(),
        'engine_number': engineNumber.trim(),
        'kilometer': int.tryParse(kilometer.trim()) ?? 0,
        'services': services,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(
          err['message'] ??
              'Failed to update job card (${response.statusCode})',
        );
      } catch (_) {
        throw Exception('Failed to update job card (${response.statusCode})');
      }
    }

    final decoded = jsonDecode(response.body);
    final jobcardData = decoded is Map<String, dynamic>
        ? (decoded['jobcard'] ?? decoded)
        : decoded;
    if (jobcardData is Map<String, dynamic>) {
      return JobCard.fromJson(jobcardData);
    }
    throw Exception('Invalid job update response');
  }

  // ─── Create Job Card ──────────────────────────────────────────────────────

  Future<JobCard> createJobCard({
    required String vehicleNumber,
    required String customerName,
    required String mobile,
    required String place,
    required String vehicleModel,
    required String vehicleMake,
    required String year,
    required String chassisNumber,
    required String engineNumber,
    required String kilometer,
    required List<String> services,
  }) async {
    final branchId = await getBranchId();

    if (branchId == null) {
      throw Exception(
        'No branch found. Please ensure your garage is registered.',
      );
    }

    final body = jsonEncode({
      'branch_id': branchId,
      'vehicle_number': vehicleNumber.trim().toUpperCase(),
      'customer_name': customerName.trim(),
      'mobile': mobile.trim(),
      'place': place.trim(),
      'vehicle_model': vehicleModel.trim(),
      'vehicle_make': vehicleMake.trim(),
      'year': year.trim(),
      'chassis_number': chassisNumber.trim(),
      'engine_number': engineNumber.trim(),
      'kilometer': int.tryParse(kilometer.trim()) ?? 0,
      'services': services,
    });

    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.jobCards),
      headers: await _headers(),
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Try to extract server error message
      try {
        final err = jsonDecode(response.body);
        throw Exception(
          err['message'] ??
              'Failed to create job card (${response.statusCode})',
        );
      } catch (_) {
        throw Exception('Failed to create job card (${response.statusCode})');
      }
    }

    final decoded = jsonDecode(response.body);
    final jobcardData = decoded is Map<String, dynamic>
        ? (decoded['jobcard'] ?? decoded)
        : decoded;

    if (jobcardData is Map<String, dynamic>) {
      return JobCard.fromJson(jobcardData);
    }

    // Fallback — shouldn't normally reach here
    return JobCard(
      id: '',
      vehicleNumber: vehicleNumber,
      customerName: customerName,
      mobile: mobile,
      place: place,
      vehicleModel: vehicleModel,
      vehicleMake: vehicleMake,
      year: year,
      chassisNumber: chassisNumber,
      engineNumber: engineNumber,
      kilometer: kilometer,
      status: 'pending',
      total: '-',
      createdAt: '-',
      services: services
          .map((service) => JobServiceItem(id: null, text: service))
          .toList(),
    );
  }
}
