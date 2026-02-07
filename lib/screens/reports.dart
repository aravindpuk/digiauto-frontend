// Monthly Report Screen UI (Static / Mock Data)
// Uses your provided theme colors

import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        backgroundColor: const Color(0xFF2E7BA6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summarySection(),
            const SizedBox(height: 24),
            _sectionTitle('Job Card Summary'),
            _jobCardList(),
            const SizedBox(height: 24),
            _sectionTitle('Spare Usage'),
            _spareList(),
            const SizedBox(height: 24),
            _sectionTitle('Labour Charges'),
            _labourList(),
          ],
        ),
      ),
    );
  }

  Widget _summarySection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: const [
        _SummaryCard(title: 'Job Cards', value: '48', icon: Icons.assignment),
        _SummaryCard(
          title: 'Vehicles',
          value: '45',
          icon: Icons.directions_car,
        ),
        _SummaryCard(
          title: 'Revenue',
          value: '₹1,24,500',
          icon: Icons.payments,
        ),
        _SummaryCard(
          title: 'Profit',
          value: '₹38,200',
          icon: Icons.trending_up,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _jobCardList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: const [
          _ListTileRow(
            title: 'JC-1023',
            subtitle: 'KL-08-AB-2345',
            trailing: '₹3,200',
          ),
          Divider(height: 1),
          _ListTileRow(
            title: 'JC-1024',
            subtitle: 'KL-11-CD-8899',
            trailing: '₹5,800',
          ),
          Divider(height: 1),
          _ListTileRow(
            title: 'JC-1025',
            subtitle: 'TN-09-EF-5678',
            trailing: '₹2,400',
          ),
        ],
      ),
    );
  }

  Widget _spareList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: const [
          _ListTileRow(
            title: 'Oil Filter',
            subtitle: 'Qty: 18',
            trailing: '₹9,000',
          ),
          Divider(height: 1),
          _ListTileRow(
            title: 'Brake Pad',
            subtitle: 'Qty: 6',
            trailing: '₹7,200',
          ),
        ],
      ),
    );
  }

  Widget _labourList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: const [
          _ListTileRow(
            title: 'General Service',
            subtitle: '15 jobs',
            trailing: '₹12,000',
          ),
          Divider(height: 1),
          _ListTileRow(
            title: 'Engine Work',
            subtitle: '5 jobs',
            trailing: '₹18,500',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2E7BA6).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xFF2E7BA6)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListTileRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _ListTileRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(
        trailing,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7BA6),
        ),
      ),
    );
  }
}
