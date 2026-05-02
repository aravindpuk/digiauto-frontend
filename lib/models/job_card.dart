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
  final List<JobServiceItem> services;
  final List<JobLabourItem> labourServices;
  final List<JobSpareItem> spares;

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
    this.labourServices = const [],
    this.spares = const [],
  });

  String get formattedCreatedAt => _formatDateTime(createdAt);

  factory JobCard.fromJson(Map<String, dynamic> json) {
    final rawServices =
        json['services'] ??
        json['complaints'] ??
        json['service_requests'] ??
        json['service_request'] ??
        [];

    return JobCard(
      id: _readString(json, ['id', 'job_id', 'jobId']),
      vehicleNumber: _readString(json, [
        'vehicle_number',
        'vehicleNo',
        'vehicle',
        'registration_number',
      ]),
      customerName: _readString(json, [
        'customer_name',
        'customerName',
        'name',
        'customer',
      ]),
      mobile: _readString(json, ['mobile', 'mobile_number', 'phone']),
      place: _readString(json, ['place', 'address', 'location']),
      vehicleModel: _readString(json, ['model', 'vehicle_model']),
      vehicleMake: _readString(json, ['make', 'vehicle_make']),
      year: _readString(json, ['year', 'vehicle_year']),
      chassisNumber: _readString(json, [
        'chassis_number',
        'chassis',
        'chassisNo',
      ]),
      engineNumber: _readString(json, ['engine_number', 'engine', 'engineNo']),
      kilometer: _readString(json, ['kilometer', 'km', 'kilometers']),
      status: _readString(json, ['status', 'job_status'], fallback: 'pending'),
      total: _readString(json, [
        'total',
        'total_amount',
        'grand_total',
      ], fallback: '-'),
      createdAt: _readString(json, [
        'created_at',
        'date',
        'createdAt',
      ], fallback: '-'),
      services: _readServices(rawServices),
      labourServices: _readLabours(json['labour_services']),
      spares: _readSpares(json['spares']),
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

  static List<JobServiceItem> _readServices(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is Map<String, dynamic>) {
              return JobServiceItem(
                id: _readInt(item, ['id']),
                text: _readString(item, [
                  'text',
                  'title',
                  'name',
                  'service',
                  'complaint',
                ]),
              );
            }
            return JobServiceItem(id: null, text: item?.toString() ?? '');
          })
          .where((item) => item.text.trim().isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [JobServiceItem(id: null, text: value.trim())];
    }

    return const [];
  }

  static List<JobLabourItem> _readLabours(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(JobLabourItem.fromJson)
        .toList();
  }

  static List<JobSpareItem> _readSpares(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(JobSpareItem.fromJson)
        .toList();
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String _formatDateTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty || raw == '-') return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} $hour12:$minute $suffix';
  }
}

class JobServiceItem {
  final int? id;
  final String text;

  const JobServiceItem({required this.id, required this.text});
}

class JobLabourItem {
  final int id;
  final int? labourId;
  final String name;
  final String amount;
  final String technician;
  final List<JobServiceItem> services;

  const JobLabourItem({
    required this.id,
    required this.labourId,
    required this.name,
    required this.amount,
    required this.technician,
    required this.services,
  });

  factory JobLabourItem.fromJson(Map<String, dynamic> json) {
    return JobLabourItem(
      id: JobCard._readInt(json, ['id']) ?? 0,
      labourId: JobCard._readInt(json, ['labour_id', 'labourId']),
      name: JobCard._readString(json, ['labour_name', 'name']),
      amount: JobCard._readString(json, [
        'amount',
        'cost',
        'price',
      ], fallback: '0.00'),
      technician: JobCard._readString(json, ['technician'], fallback: '-'),
      services: JobCard._readServices(json['services'] ?? json['complaints']),
    );
  }
}

class JobSpareItem {
  final int id;
  final String partName;
  final int quantity;
  final String mrp;
  final String amount;
  final List<JobServiceItem> services;

  const JobSpareItem({
    required this.id,
    required this.partName,
    required this.quantity,
    required this.mrp,
    required this.amount,
    required this.services,
  });

  factory JobSpareItem.fromJson(Map<String, dynamic> json) {
    return JobSpareItem(
      id: JobCard._readInt(json, ['id']) ?? 0,
      partName: JobCard._readString(json, ['part_name', 'name']),
      quantity: JobCard._readInt(json, ['quantity', 'qty']) ?? 0,
      mrp: JobCard._readString(json, ['mrp', 'price'], fallback: '0.00'),
      amount: JobCard._readString(json, ['amount', 'total'], fallback: '0.00'),
      services: JobCard._readServices(json['services'] ?? json['complaints']),
    );
  }
}
