import 'package:digiauto/models/job_card.dart';
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key, required this.job});

  final JobCard job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Latest Job Card')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 14),
                    _details(),
                    const SizedBox(height: 14),
                    _services(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: Color(0xFF2E7BA6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _value(job.vehicleNumber).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17384C),
                  ),
                ),
              ),
              _status(job.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Job Card DIGI-J${job.id.padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            job.formattedCreatedAt,
            style: const TextStyle(color: Color(0xFF667985)),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    final details = <(IconData, String, String)>[
      (Icons.person_outline, 'Customer', job.customerName),
      (
        Icons.directions_car_outlined,
        'Vehicle',
        '${job.vehicleMake} ${job.vehicleModel}',
      ),
      (Icons.speed_outlined, 'Kilometer', job.kilometer),
      (Icons.location_on_outlined, 'Place', job.place),
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Card Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(item.$1, color: const Color(0xFF2E7BA6), size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: Color(0xFF667985),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _value(item.$3),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _services() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (job.services.isEmpty)
            const Text(
              'No service details available.',
              style: TextStyle(color: Color(0xFF667985)),
            )
          else
            ...job.services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 19,
                      color: Color(0xFF2E7BA6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(service.text)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _status(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7BA6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _value(status),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  String _value(String value) => value.trim().isEmpty ? '-' : value.trim();
}
