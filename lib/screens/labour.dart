import 'dart:async';

import 'package:digiauto/services/labour_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabourForm extends StatefulWidget {
  const LabourForm({super.key});

  @override
  State<LabourForm> createState() => _LabourFormState();
}

class _LabourFormState extends State<LabourForm> {
  final LabourService _service = LabourService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _costCtrl = TextEditingController();

  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  int? _selectedLabourId;
  bool _isEditMode = false;
  bool _searching = false;
  bool _saving = false;
  bool _isError = false;
  String? _message;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isEditMode) {
      await _updateLabour();
      return;
    }
    await _createLabour();
  }

  Future<void> _createLabour() async {
    final name = _nameCtrl.text.trim();
    final cost = _costCtrl.text.trim();

    if (!_validate(name, cost)) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await _service.createLabour(name: name, cost: cost);
      _clearForm();
      _showMessage("Labour saved.");
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateLabour() async {
    final name = _nameCtrl.text.trim();
    final cost = _costCtrl.text.trim();

    if (_selectedLabourId == null) {
      _showMessage("Search and select a labour to update.", isError: true);
      return;
    }
    if (!_validate(name, cost)) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final updated = await _service.updateLabour(
        labourId: _selectedLabourId!,
        name: name,
        cost: cost,
      );
      setState(() {
        _selectedLabourId = updated['id'] as int?;
        _nameCtrl.text = (updated['name'] ?? name).toString();
        _costCtrl.text = (updated['cost'] ?? cost).toString();
      });
      _showMessage("Labour updated.");
    } catch (e) {
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validate(String name, String cost) {
    if (name.isEmpty) {
      _showMessage("Enter labour name.", isError: true);
      return false;
    }
    final parsedCost = double.tryParse(cost);
    if (parsedCost == null || parsedCost < 0) {
      _showMessage("Enter a valid labour cost.", isError: true);
      return false;
    }
    return true;
  }

  void _onNameChanged(String value) {
    _selectedLabourId = null;
    if (_isEditMode) _costCtrl.clear();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final query = value.trim();
      if (!_isEditMode || query.length < 2) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _searching = false;
          });
        }
        return;
      }

      try {
        if (mounted) setState(() => _searching = true);
        final results = await _service.searchLabour(query);
        if (!mounted || _nameCtrl.text.trim() != query) return;
        setState(() => _suggestions = results.take(8).toList());
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted && _nameCtrl.text.trim() == query) {
          setState(() => _searching = false);
        }
      }
    });
  }

  void _selectLabour(Map<String, dynamic> labour) {
    final cost = labour['suggested_price'] ?? labour['cost'];
    setState(() {
      _selectedLabourId = labour['id'] as int?;
      _nameCtrl.text = (labour['name'] ?? '').toString();
      _costCtrl.text = (cost ?? '').toString();
      _suggestions = [];
      _message = null;
    });
  }

  void _setMode(bool editMode) {
    if (_isEditMode == editMode) return;
    setState(() {
      _isEditMode = editMode;
      _message = null;
      _clearForm();
    });
  }

  void _clearForm() {
    _selectedLabourId = null;
    _suggestions = [];
    _searching = false;
    _nameCtrl.clear();
    _costCtrl.clear();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isError = isError;
    });
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Labour"),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeSelector(),
            const SizedBox(height: 18),
            Text(
              _isEditMode ? "Update Labour" : "Add Labour",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _nameSearchField(),
            _textField(
              controller: _costCtrl,
              label: "Labour Cost",
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            if (_message != null) ...[const SizedBox(height: 4), _messageBox()],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isEditMode ? Icons.check_rounded : Icons.add_rounded,
                      ),
                label: Text(
                  _saving
                      ? "Saving..."
                      : _isEditMode
                      ? "Update Labour"
                      : "Save Labour",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _modeButton("Add", !_isEditMode, () => _setMode(false)),
          _modeButton("Edit", _isEditMode, () => _setMode(true)),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameSearchField() {
    return Column(
      children: [
        _textField(
          controller: _nameCtrl,
          label: "Labour Name",
          hint: _isEditMode ? "Search labour name" : "Enter labour name",
          icon: Icons.engineering_outlined,
          onChanged: _onNameChanged,
          suffixIcon: _isEditMode
              ? _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _selectedLabourId == null
                    ? const Icon(Icons.search)
                    : const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E8ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _suggestions.map((labour) {
                final name = (labour['name'] ?? '').toString();
                final price = (labour['suggested_price'] ?? labour['cost'])
                    ?.toString();
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.engineering_outlined),
                  title: Text(name),
                  subtitle: _isEditMode
                      ? Text("Cost Rs ${price ?? ''}")
                      : price == null
                      ? null
                      : Text("Cost Rs $price"),
                  onTap: () => _selectLabour(labour),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _messageBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isError ? const Color(0xFFFFF1F1) : const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isError ? const Color(0xFFFFC9C9) : const Color(0xFFC8EBCF),
        ),
      ),
      child: Text(
        _message!,
        style: TextStyle(
          color: _isError ? Colors.red.shade700 : Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
