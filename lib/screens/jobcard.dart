import 'package:flutter/material.dart';

class JobCardFormScreen extends StatefulWidget {
  const JobCardFormScreen({super.key});

  @override
  State<JobCardFormScreen> createState() => _JobCardFormScreenState();
}

class _JobCardFormScreenState extends State<JobCardFormScreen> {
  final _vehicleNoCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _chassisCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();

  final List<TextEditingController> _complaints = [];

  @override
  void initState() {
    super.initState();
    _complaints.add(TextEditingController());
  }

  @override
  void dispose() {
    for (var c in _complaints) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Job Card")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _vehicleNumberSection(theme),
            _customerSection(theme),
            _vehicleDetailsSection(theme),
            _jobDetailsSection(theme),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                ),
                onPressed: () {},
                child: Text(
                  "Create Job Card",
                  style: TextStyle(color: theme.colorScheme.onSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleNumberSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _vehicleNoCtrl,
                decoration: const InputDecoration(
                  labelText: "Vehicle Registration Number",
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.search),
              color: theme.colorScheme.primary,
              onPressed: () {
                // API call later (fetch vehicle)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Customer Details", theme),
            TextField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(labelText: "Customer Name"),
            ),
            TextField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile Number"),
            ),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Address"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleDetailsSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Vehicle Details", theme),

            /// MAKE AUTOCOMPLETE
            Autocomplete<String>(
              optionsBuilder: (text) {
                if (text.text.isEmpty) return const Iterable.empty();
                return ["Honda", "Hyundai", "Suzuki", "Tata", "Toyota"].where(
                  (e) => e.toLowerCase().contains(text.text.toLowerCase()),
                );
              },
              onSelected: (val) => _makeCtrl.text = val,
              fieldViewBuilder: (_, ctrl, focus, __) {
                ctrl.text = _makeCtrl.text;
                return TextField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: const InputDecoration(labelText: "Vehicle Make"),
                );
              },
            ),

            /// MODEL AUTOCOMPLETE
            Autocomplete<String>(
              optionsBuilder: (text) {
                if (text.text.isEmpty) return const Iterable.empty();
                return ["Swift", "City", "Creta", "Nexon"].where(
                  (e) => e.toLowerCase().contains(text.text.toLowerCase()),
                );
              },
              onSelected: (val) => _modelCtrl.text = val,
              fieldViewBuilder: (_, ctrl, focus, __) {
                ctrl.text = _modelCtrl.text;
                return TextField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: const InputDecoration(labelText: "Vehicle Model"),
                );
              },
            ),

            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Manufacture Year"),
            ),
            TextField(
              controller: _engineCtrl,
              decoration: const InputDecoration(
                labelText: "Engine Number (Optional)",
              ),
            ),
            TextField(
              controller: _chassisCtrl,
              decoration: const InputDecoration(
                labelText: "Chassis Number (Optional)",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobDetailsSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Job Card Details", theme),
            TextField(
              controller: _kmCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Current Kilometer"),
            ),
            const SizedBox(height: 12),

            const Text("Complaints"),
            const SizedBox(height: 8),

            ..._complaints.asMap().entries.map((entry) {
              final i = entry.key;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _complaints[i],
                      decoration: InputDecoration(
                        hintText: "Complaint ${i + 1}",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() => _complaints.removeAt(i));
                    },
                  ),
                ],
              );
            }),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add, color: theme.colorScheme.secondary),
                label: const Text("Add Complaint"),
                onPressed: () {
                  setState(() => _complaints.add(TextEditingController()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
