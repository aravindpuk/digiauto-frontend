import 'package:flutter/material.dart';

class SpareForm extends StatelessWidget {
  const SpareForm({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spare"),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modeSelector(theme),
                const SizedBox(height: 20),
                _partSearchField(),
                _textField("Part Number"),
                _twoColumnFields(),
                _textField("Purchase Rate"),
                _textField("Total Amount", enabled: false),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                    onPressed: () {},
                    child: const Text("Save Spare"),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _partSearchField() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: "Part Name",
            hintText: "Search or enter part name",
            suffixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _textField(String label, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        enabled: enabled,
        keyboardType: label.contains("Rate") || label.contains("Amount")
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _twoColumnFields() {
    return Row(
      children: [
        Expanded(child: _textField("Quantity")),
        const SizedBox(width: 12),
        Expanded(child: _textField("Selling Rate (MRP)")),
      ],
    );
  }
}
