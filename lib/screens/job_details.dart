import 'package:digiauto/models/job_card.dart';
import 'package:flutter/material.dart';

class JobDetailsPage extends StatelessWidget {
  const JobDetailsPage({
    super.key,
    required this.job,
  });

  final JobCard job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Job Details", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7BA6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Job ID: ${job.id.isEmpty ? '-' : job.id}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7BA6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Created: ${job.createdAt}"),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(job.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.isEmpty ? '-' : job.status,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _section(
            title: "Customer Details",
            lines: [
              "Name: ${job.customerName.isEmpty ? '-' : job.customerName}",
              "Mobile: ${job.mobile.isEmpty ? '-' : job.mobile}",
              "Place: ${job.place.isEmpty ? '-' : job.place}",
            ],
          ),
          const SizedBox(height: 10),
          _section(
            title: "Vehicle Details",
            lines: [
              "Vehicle No: ${job.vehicleNumber.isEmpty ? '-' : job.vehicleNumber}",
              "Model: ${job.vehicleModel.isEmpty ? '-' : job.vehicleModel}",
              "Make: ${job.vehicleMake.isEmpty ? '-' : job.vehicleMake}",
              "Year: ${job.year.isEmpty ? '-' : job.year}",
              "Chassis: ${job.chassisNumber.isEmpty ? '-' : job.chassisNumber}",
              "Engine: ${job.engineNumber.isEmpty ? '-' : job.engineNumber}",
              "Kilometer: ${job.kilometer.isEmpty ? '-' : job.kilometer}",
            ],
          ),
          const SizedBox(height: 10),
          _section(
            title: "Billing Summary",
            lines: [
              "Grand Total: ${job.total}",
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _box(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Services",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7BA6),
                  ),
                ),
                const SizedBox(height: 10),
                if (job.services.isEmpty)
                  const Text("No service items available from the API yet.")
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.services
                        .map((service) => Chip(label: Text(service)))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    String? title,
    List<String> lines = const [],
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7BA6),
                  ),
                ),
              if (title != null) const SizedBox(height: 8),
              ...lines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  )),
            ],
          ),
    );
  }

  static BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "active":
      case "in progress":
        return const Color.fromARGB(255, 50, 121, 162);
      case "completed":
        return const Color.fromARGB(255, 110, 202, 113);
      case "delivered":
        return const Color.fromARGB(255, 61, 152, 64);
      default:
        return Colors.grey;
    }
  }
}
