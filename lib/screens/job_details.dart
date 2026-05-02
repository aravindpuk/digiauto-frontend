import 'package:digiauto/models/job_card.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:flutter/material.dart';

class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key, required this.job});

  final JobCard job;

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late Future<JobCard> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = JobcardService().fetchJobDetail(widget.job.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JobCard>(
      future: _detailFuture,
      initialData: widget.job,
      builder: (context, snapshot) {
        final job = snapshot.data ?? widget.job;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text(
              "Job Details",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2E7BA6),
            actions: [
              IconButton(
                tooltip: "Refresh",
                onPressed: () {
                  setState(() {
                    _detailFuture = JobcardService().fetchJobDetail(job.id);
                  });
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final future = JobcardService().fetchJobDetail(job.id);
              setState(() => _detailFuture = future);
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _jobHeader(job),
                const SizedBox(height: 12),
                _infoGrid(job),
                const SizedBox(height: 12),
                _billingSummary(job),
                const SizedBox(height: 12),
                _serviceBreakdown(job),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _jobHeader(JobCard job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F3F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.car_repair_rounded,
              color: Color(0xFF2E7BA6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DIGI-J${job.id.padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17384C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_dash(job.vehicleNumber).toUpperCase()}  •  ${_dash(job.formattedCreatedAt)}",
                  style: const TextStyle(color: Color(0xFF667985)),
                ),
              ],
            ),
          ),
          _statusPill(job.status),
        ],
      ),
    );
  }

  Widget _infoGrid(JobCard job) {
    final items = [
      _InfoItem("Customer", _dash(job.customerName), Icons.person_outline),
      _InfoItem("Mobile", _dash(job.mobile), Icons.call_outlined),
      _InfoItem("Place", _dash(job.place), Icons.location_on_outlined),
      _InfoItem(
        "Vehicle",
        "${_dash(job.vehicleMake)} ${_dash(job.vehicleModel)}",
        Icons.directions_car_outlined,
      ),
      _InfoItem("Year", _dash(job.year), Icons.event_outlined),
      _InfoItem("Kilometer", _dash(job.kilometer), Icons.speed_outlined),
      _InfoItem("Chassis", _dash(job.chassisNumber), Icons.pin_outlined),
      _InfoItem("Engine", _dash(job.engineNumber), Icons.settings_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 520;
          return GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              mainAxisExtent: 58,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, index) => _infoTile(items[index]),
          );
        },
      ),
    );
  }

  Widget _billingSummary(JobCard job) {
    final labourTotal = job.labourServices.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.amount) ?? 0),
    );
    final spareTotal = job.spares.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.amount) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        children: [
          Expanded(child: _amountBlock("Labour", labourTotal)),
          Container(width: 1, height: 42, color: const Color(0xFFE7EEF2)),
          Expanded(child: _amountBlock("Spares", spareTotal)),
          Container(width: 1, height: 42, color: const Color(0xFFE7EEF2)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(color: Color(0xFF667985), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(job.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF17384C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceBreakdown(JobCard job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Service & Labour",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17384C),
            ),
          ),
          const SizedBox(height: 12),
          if (job.services.isEmpty)
            const Text("No service items available.")
          else
            ...job.services.map((service) => _serviceCard(job, service)),
          if (job.labourServices.any((item) => item.services.isEmpty))
            _unassignedLabour(job),
        ],
      ),
    );
  }

  Widget _serviceCard(JobCard job, JobServiceItem service) {
    final labours = job.labourServices.where((item) {
      return item.services.any(
        (linked) =>
            (service.id != null && linked.id == service.id) ||
            linked.text.toLowerCase() == service.text.toLowerCase(),
      );
    }).toList();
    final spares = job.spares.where((item) {
      return item.services.any(
        (linked) =>
            (service.id != null && linked.id == service.id) ||
            linked.text.toLowerCase() == service.text.toLowerCase(),
      );
    }).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17384C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (labours.isEmpty && spares.isEmpty)
            const Text(
              "No labour or spare added for this service yet.",
              style: TextStyle(color: Color(0xFF667985)),
            )
          else ...[
            ...labours.map((item) => _labourRow(item)),
            ...spares.map((item) => _spareRow(item)),
          ],
        ],
      ),
    );
  }

  Widget _unassignedLabour(JobCard job) {
    final labours = job.labourServices
        .where((item) => item.services.isEmpty)
        .toList();
    if (labours.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0DEAA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Labour not linked to a service",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...labours.map((item) => _labourRow(item)),
        ],
      ),
    );
  }

  Widget _labourRow(JobLabourItem item) {
    return _lineItem(
      icon: Icons.engineering_outlined,
      title: item.name,
      subtitle: "Labour charge",
      amount: item.amount,
    );
  }

  Widget _spareRow(JobSpareItem item) {
    return _lineItem(
      icon: Icons.build_outlined,
      title: item.partName,
      subtitle: "Qty ${item.quantity} x ${_money(item.mrp)}",
      amount: item.amount,
    );
  }

  Widget _lineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7BA6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667985),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(_InfoItem item) {
    return Row(
      children: [
        Icon(item.icon, color: const Color(0xFF2E7BA6), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: const TextStyle(color: Color(0xFF667985), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                item.value.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountBlock(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667985), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          _money(value.toStringAsFixed(2)),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static String _dash(String value) =>
      value.trim().isEmpty ? '-' : value.trim();

  static String _money(String value) {
    if (value == '-') return '-';
    return "Rs ${value.trim().isEmpty ? '0.00' : value}";
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFD78318);
      case "active":
      case "in progress":
        return const Color(0xFF2E7BA6);
      case "completed":
        return const Color(0xFF3E9361);
      case "delivered":
        return const Color(0xFF28784D);
      default:
        return Colors.grey;
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem(this.label, this.value, this.icon);
}
