class JobCard {
  final String id;
  final String vehicleNumber;
  final String customerName;
  final String mobile;
  final String place;
  final String vehicleModel;
  final String vehicleMake;
  final String year;
  final String chassisNumber;
  final String engineNumber;
  final String kilometer;
  final String status;
  final String total;
  final String createdAt;
  final List<String> services;

  const JobCard({
    required this.id,
    required this.vehicleNumber,
    required this.customerName,
    required this.mobile,
    required this.place,
    required this.vehicleModel,
    required this.vehicleMake,
    required this.year,
    required this.chassisNumber,
    required this.engineNumber,
    required this.kilometer,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.services,
  });

  factory JobCard.fromJson(Map<String, dynamic> json) {
    final rawServices =
        json['services'] ??
        json['complaints'] ??
        json['service_requests'] ??
        json['service_request'] ??
        [];

    return JobCard(
      id: _readString(json, ['id', 'job_id', 'jobId']),
      vehicleNumber: _readString(
        json,
        ['vehicle_number', 'vehicleNo', 'vehicle', 'registration_number'],
      ),
      customerName: _readString(
        json,
        ['customer_name', 'customerName', 'name', 'customer'],
      ),
      mobile: _readString(json, ['mobile', 'mobile_number', 'phone']),
      place: _readString(json, ['place', 'address', 'location']),
      vehicleModel: _readString(json, ['model', 'vehicle_model']),
      vehicleMake: _readString(json, ['make', 'vehicle_make']),
      year: _readString(json, ['year', 'vehicle_year']),
      chassisNumber: _readString(
        json,
        ['chassis_number', 'chassis', 'chassisNo'],
      ),
      engineNumber: _readString(
        json,
        ['engine_number', 'engine', 'engineNo'],
      ),
      kilometer: _readString(json, ['kilometer', 'km', 'kilometers']),
      status: _readString(json, ['status', 'job_status'], fallback: 'pending'),
      total: _readString(
        json,
        ['total', 'total_amount', 'grand_total'],
        fallback: '-',
      ),
      createdAt: _readString(
        json,
        ['created_at', 'date', 'createdAt'],
        fallback: '-',
      ),
      services: _readServices(rawServices),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  static List<String> _readServices(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _readString(
                item,
                ['title', 'name', 'service', 'complaint'],
              );
            }
            return item?.toString() ?? '';
          })
          .where((item) => item.trim().isNotEmpty)
          .cast<String>()
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return const [];
  }
}
