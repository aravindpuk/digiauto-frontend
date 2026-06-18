class ReportSummary {
  final int totalJobs;
  final int pendingJobs;
  final int deliveredJobs;
  final double income;
  final double spareIncome;
  final double labourIncome;

  const ReportSummary({
    required this.totalJobs,
    required this.pendingJobs,
    required this.deliveredJobs,
    required this.income,
    required this.spareIncome,
    required this.labourIncome,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalJobs: json['total_jobs'] as int? ?? 0,
      pendingJobs: json['pending_jobs'] as int? ?? 0,
      deliveredJobs: json['delivered_jobs'] as int? ?? 0,
      income: double.tryParse(json['income']?.toString() ?? '') ?? 0,
      spareIncome: double.tryParse(json['spare_income']?.toString() ?? '') ?? 0,
      labourIncome:
          double.tryParse(json['labour_income']?.toString() ?? '') ?? 0,
    );
  }
}

class DeliveredJobItem {
  final int id;
  final String jobId;
  final String vehicleNumber;
  final String customerName;
  final double total;
  final double spareAmount;
  final double labourAmount;

  const DeliveredJobItem({
    required this.id,
    required this.jobId,
    required this.vehicleNumber,
    required this.customerName,
    required this.total,
    required this.spareAmount,
    required this.labourAmount,
  });

  factory DeliveredJobItem.fromJson(Map<String, dynamic> json) {
    return DeliveredJobItem(
      id: json['id'] as int? ?? 0,
      jobId: (json['job_id'] ?? '').toString(),
      vehicleNumber: (json['vehicle_number'] ?? '').toString(),
      customerName: (json['customer_name'] ?? '').toString(),
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
      spareAmount: double.tryParse(json['spare_amount']?.toString() ?? '') ?? 0,
      labourAmount:
          double.tryParse(json['labour_amount']?.toString() ?? '') ?? 0,
    );
  }
}

class GarageReport {
  final String period;
  final ReportSummary summary;
  final List<DeliveredJobItem> deliveredJobs;

  const GarageReport({
    required this.period,
    required this.summary,
    required this.deliveredJobs,
  });

  factory GarageReport.fromJson(Map<String, dynamic> json) {
    return GarageReport(
      period: (json['period'] ?? '').toString(),
      summary: ReportSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? {},
      ),
      deliveredJobs: ((json['delivered_jobs_list'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(DeliveredJobItem.fromJson)
          .toList(),
    );
  }
}
