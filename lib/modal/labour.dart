import 'package:flutter/material.dart';

class LabourFormSheet extends StatelessWidget {
  const LabourFormSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          /// Title
          Text(
            "Labour",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          /// Add / Edit Selector (UI only)
          _modeSelector(theme),

          const SizedBox(height: 20),

          /// Labour Name
          TextField(
            decoration: const InputDecoration(
              labelText: "Labour Name",
              hintText: "e.g. Engine Service",
            ),
          ),

          const SizedBox(height: 12),

          /// Labour Cost
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Labour Cost",
              prefixText: "₹ ",
            ),
          ),

          const SizedBox(height: 24),

          /// Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Save Labour"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [_modeChip("Add"), _modeChip("Edit")]),
    );
  }

  Widget _modeChip(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: label == "Add" ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
