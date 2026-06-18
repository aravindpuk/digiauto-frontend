import 'package:digiauto/models/report_data.dart';
import 'package:digiauto/services/report_service.dart';
import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _service = ReportService();

  String _period = 'today';
  DateTimeRange? _customRange;
  late Future<GarageReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<GarageReport> _loadReport() {
    return _service.fetchReport(
      period: _period,
      startDate: _customRange?.start,
      endDate: _customRange?.end,
    );
  }

  void _selectPeriod(String period) {
    if (period == 'custom') {
      _pickCustomRange();
      return;
    }
    setState(() {
      _period = period;
      _customRange = null;
      _reportFuture = _loadReport();
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
    );
    if (picked == null) return;
    setState(() {
      _period = 'custom';
      _customRange = picked;
      _reportFuture = _loadReport();
    });
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _refresh() async {
    setState(() => _reportFuture = _loadReport());
    await _reportFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF2E7BA6),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<GarageReport>(
          future: _reportFuture,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _periodSelector(),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    _errorState()
                  else
                    _reportBody(snapshot.data!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    final options = const [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('custom', 'Custom'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final selected = _period == opt.$1;
          final label = opt.$1 == 'custom' && _customRange != null
              ? '${_fmt(_customRange!.start)} - ${_fmt(_customRange!.end)}'
              : opt.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: const Color(0xFF2E7BA6),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => _selectPeriod(opt.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            SizedBox(height: 8),
            Text('Could not load report. Pull down to retry.'),
          ],
        ),
      ),
    );
  }

  Widget _reportBody(GarageReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statsGrid(report.summary),
        const SizedBox(height: 18),
        const Text(
          'Delivered Jobs',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (report.deliveredJobs.isEmpty)
          _emptyCard('No jobs delivered in this period.')
        else
          Column(
            children: report.deliveredJobs
                .map((job) => _JobReportCard(item: job))
                .toList(),
          ),
      ],
    );
  }

  Widget _statsGrid(ReportSummary s) {
    final stats = [
      _StatData(
        'Total Jobs',
        '${s.totalJobs}',
        Icons.assignment_outlined,
        const Color(0xFF2E7BA6),
      ),
      _StatData(
        'Delivered',
        '${s.deliveredJobs}',
        Icons.check_circle_rounded,
        const Color(0xFF2E8B57),
      ),
      _StatData(
        'Pending',
        '${s.pendingJobs}',
        Icons.pending_actions_rounded,
        const Color(0xFFD78318),
      ),
      _StatData(
        'Total Income',
        _money(s.income),
        Icons.account_balance_wallet_outlined,
        const Color(0xFF2E7BA6),
      ),
      _StatData(
        'Spare Income',
        _money(s.spareIncome),
        Icons.build_outlined,
        const Color(0xFF6C63A8),
      ),
      _StatData(
        'Labour Income',
        _money(s.labourIncome),
        Icons.engineering_outlined,
        const Color(0xFFFF5733),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisExtent: 60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatTile(data: stats[i]),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EEF2)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  String _money(double value) => _formatIndianCurrency(value);
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatTile extends StatelessWidget {
  final _StatData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EEF2)),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: data.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobReportCard extends StatelessWidget {
  final DeliveredJobItem item;
  const _JobReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.jobId} • ${item.vehicleNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.customerName,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (item.spareAmount > 0 || item.labourAmount > 0) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (item.spareAmount > 0)
                        Text(
                          'Spare: ${_formatIndianCurrency(item.spareAmount)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey,
                          ),
                        ),
                      if (item.labourAmount > 0)
                        Text(
                          'Labour: ${_formatIndianCurrency(item.labourAmount)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatIndianCurrency(item.total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7BA6),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatIndianCurrency(double value) {
  final isNegative = value < 0;
  value = value.abs();
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final decimalPart = parts[1];
  String integerPart = parts[0];

  String lastThree = integerPart.length > 3
      ? integerPart.substring(integerPart.length - 3)
      : integerPart;
  String otherDigits = integerPart.length > 3
      ? integerPart.substring(0, integerPart.length - 3)
      : '';

  if (otherDigits.isNotEmpty) {
    otherDigits = otherDigits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (match) => '${match[1]},',
    );
    lastThree = ',$lastThree';
  }

  return '${isNegative ? '-' : ''}₹$otherDigits$lastThree.$decimalPart';
}
