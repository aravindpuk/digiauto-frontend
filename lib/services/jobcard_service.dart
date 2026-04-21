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

  Future<List<JobCard>> fetchJobs() async {
    final response = await http.get(
      Uri.parse(baseUrl + ApiEndpoints.jobCards),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch jobs (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> items = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic>
              ? (decoded['results'] ??
                    decoded['data'] ??
                    decoded['jobs'] ??
                    decoded['jobcards'] ??
                    [])
              : []);

    return items
        .whereType<Map<String, dynamic>>()
        .map(JobCard.fromJson)
        .toList();
  }

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
    final body = jsonEncode({
      'vehicle_number': vehicleNumber,
      'customer_name': customerName,
      'mobile': mobile,
      'place': place,
      'model': vehicleModel,
      'make': vehicleMake,
      'year': year,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'kilometer': kilometer,
      'services': services,
    });

    final response = await http.post(
      Uri.parse(baseUrl + ApiEndpoints.jobCards),
      headers: await _headers(),
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create job card (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return JobCard.fromJson(decoded);
    }

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
      services: services,
    );
  }
}
