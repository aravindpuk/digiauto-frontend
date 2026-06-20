import 'dart:async';

import 'package:digiauto/services/spare_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpareForm extends StatefulWidget {
  const SpareForm({super.key});

  @override
  State<SpareForm> createState() => _SpareFormState();
}

class _SpareFormState extends State<SpareForm> {
  final SpareService _service = SpareService();
  final TextEditingController _partNameCtrl = TextEditingController();
  final TextEditingController _partNumberCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _mrpCtrl = TextEditingController();
  final TextEditingController _purchaseRateCtrl = TextEditingController();

  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _stockItems = [];
  int? _selectedSpareId;
  int? _selectedStockId;
  bool _isEditMode = false;
  bool _loadingStock = false;
  bool _searchingSpares = false;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  double get _totalPurchase {
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_purchaseRateCtrl.text.trim()) ?? 0;
    return quantity * rate;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _partNameCtrl.dispose();
    _partNumberCtrl.dispose();
    _quantityCtrl.dispose();
    _mrpCtrl.dispose();
    _purchaseRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isEditMode) {
      await _saveEdit();
      return;
    }
    await _saveAdd();
  }

  Future<void> _saveAdd() async {
    final partName = _partNameCtrl.text.trim();
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    final mrp = _mrpCtrl.text.trim();
    final purchaseRate = _purchaseRateCtrl.text.trim();
    final branchId = await getBranchId();

    if (partName.isEmpty) {
      _showMessage("Enter spare name.", isError: true);
      return;
    }
    if (branchId == null) {
      _showMessage("Branch not found. Please login again.", isError: true);
      return;
    }
    if (quantity == null || quantity <= 0) {
      _showMessage("Enter a valid quantity.", isError: true);
      return;
    }
    if (double.tryParse(mrp) == null || double.tryParse(purchaseRate) == null) {
      _showMessage("Enter valid MRP and purchase rate.", isError: true);
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final spare = await _service.createSpare(
        partName: partName,
        partNumber: _partNumberCtrl.text.trim(),
      );

      await _service.addStock(
        spareId: spare['id'] as int,
        branchId: branchId,
        quantity: quantity,
        mrp: mrp,
        purchaseAmount: purchaseRate,
      );

      _clearForm();
      _showMessage("Spare stock saved.");
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEdit() async {
    final partName = _partNameCtrl.text.trim();
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    final mrp = _mrpCtrl.text.trim();
    final purchaseRate = _purchaseRateCtrl.text.trim();

    if (_selectedSpareId == null) {
      _showMessage("Search and select a spare to edit.", isError: true);
      return;
    }
    if (partName.isEmpty) {
      _showMessage("Enter spare name.", isError: true);
      return;
    }
    if (_selectedStockId != null) {
      if (quantity == null || quantity < 0) {
        _showMessage("Enter a valid quantity.", isError: true);
        return;
      }
      if (double.tryParse(mrp) == null ||
          double.tryParse(purchaseRate) == null) {
        _showMessage("Enter valid MRP and purchase rate.", isError: true);
        return;
      }
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final updatedSpare = await _service.updateSpare(
        spareId: _selectedSpareId!,
        partName: partName,
        partNumber: _partNumberCtrl.text.trim(),
      );
      _selectedSpareId = updatedSpare['id'] as int? ?? _selectedSpareId;
      if (_selectedStockId != null) {
        await _service.updateStock(
          stockId: _selectedStockId!,
          quantity: quantity!,
          mrp: mrp,
          purchaseAmount: purchaseRate,
        );
      }
      await _loadStock();
      _showMessage(
        _selectedStockId == null
            ? "Spare details updated."
            : "Spare stock updated.",
      );
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadStock() async {
    final branchId = await getBranchId();
    if (branchId == null) {
      _showMessage("Branch not found. Please login again.", isError: true);
      return;
    }
    setState(() => _loadingStock = true);
    try {
      final items = await _service.listStock(branchId);
      if (!mounted) return;
      setState(() {
        _stockItems = items;
        _loadingStock = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStock = false);
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _clearForm() {
    _selectedSpareId = null;
    _selectedStockId = null;
    _partNameCtrl.clear();
    _partNumberCtrl.clear();
    _quantityCtrl.clear();
    _mrpCtrl.clear();
    _purchaseRateCtrl.clear();
    _suggestions = [];
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isError = isError;
    });
  }

  void _onPartNameChanged(String value) {
    _selectedSpareId = null;
    _selectedStockId = null;
    if (_isEditMode) {
      _partNumberCtrl.clear();
      _quantityCtrl.clear();
      _mrpCtrl.clear();
      _purchaseRateCtrl.clear();
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final query = value.trim();
      if (query.length < 2) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _searchingSpares = false;
          });
        }
        return;
      }
      try {
        if (mounted) setState(() => _searchingSpares = true);
        final results = await _service.searchSpares(query);
        if (!mounted || _partNameCtrl.text.trim() != query) return;
        setState(() => _suggestions = results.take(6).toList());
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted && _partNameCtrl.text.trim() == query) {
          setState(() => _searchingSpares = false);
        }
      }
    });
  }

  Future<void> _selectSpare(Map<String, dynamic> spare) async {
    final spareId = spare['id'] as int?;
    if (spareId == null) return;

    if (_isEditMode && _stockItems.isEmpty) {
      await _loadStock();
    }

    Map<String, dynamic> stock = {};
    if (_isEditMode) {
      stock = _stockForSpareId(spareId);

      if (stock.isEmpty) {
        setState(() {
          _selectedSpareId = spareId;
          _selectedStockId = null;
          _partNameCtrl.text = (spare['partname'] ?? spare['name'] ?? '')
              .toString();
          _partNumberCtrl.text = spare['partnumber']?.toString() ?? '';
          _quantityCtrl.clear();
          _mrpCtrl.clear();
          _purchaseRateCtrl.clear();
          _suggestions = [];
        });
        _showMessage(
          "No stock details found. You can update the spare name and part number.",
        );
        return;
      }
    }

    setState(() {
      _selectedSpareId = spareId;
      _partNameCtrl.text = (spare['partname'] ?? spare['name'] ?? '')
          .toString();
      _partNumberCtrl.text = spare['partnumber']?.toString() ?? '';
      if (_isEditMode) {
        _selectedStockId = stock['id'] as int?;
        _quantityCtrl.text = (stock['quantity'] ?? '').toString();
        _mrpCtrl.text = (stock['mrp'] ?? '').toString();
        _purchaseRateCtrl.text = (stock['purchase_amount'] ?? '').toString();
      }
      _suggestions = [];
      _message = null;
    });
  }

  Map<String, dynamic> _stockForSpareId(int spareId) {
    return _stockItems.firstWhere((item) {
      final itemSpare = item['spare'] as Map?;
      return itemSpare?['id'] == spareId;
    }, orElse: () => {});
  }

  String _fieldValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  void _setMode(bool editMode) {
    if (_isEditMode == editMode) return;
    setState(() {
      _isEditMode = editMode;
      _message = null;
      _suggestions = [];
      _searchingSpares = false;
      _selectedSpareId = null;
      _selectedStockId = null;
      _partNameCtrl.clear();
      _partNumberCtrl.clear();
      _quantityCtrl.clear();
      _mrpCtrl.clear();
      _purchaseRateCtrl.clear();
    });
    if (editMode) _loadStock();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spare Stock"),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modeSelector(theme),
            const SizedBox(height: 18),
            Text(
              _isEditMode ? "Edit Inventory" : "Add Inventory",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _partSearchField(),
            _textField(
              controller: _partNumberCtrl,
              label: "Part Number",
              hint: "Optional",
            ),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _quantityCtrl,
                    label: "Quantity",
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _mrpCtrl,
                    label: "MRP",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _textField(
              controller: _purchaseRateCtrl,
              label: "Purchase Rate",
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            _totalBox(theme),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _isError ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? "Saving..."
                      : _isEditMode
                      ? "Update Spare Stock"
                      : "Save Spare Stock",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partSearchField() {
    return Column(
      children: [
        TextField(
          controller: _partNameCtrl,
          textInputAction: TextInputAction.next,
          onChanged: _onPartNameChanged,
          decoration: InputDecoration(
            labelText: "Part Name",
            hintText: _isEditMode
                ? "Search spare name to edit"
                : "Search or enter part name",
            suffixIcon: _isEditMode
                ? _searchingSpares || _loadingStock
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedSpareId == null
                      ? const Icon(Icons.search)
                      : const Icon(Icons.check_circle, color: Colors.green)
                : _selectedSpareId == null
                ? const Icon(Icons.search)
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E8ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _suggestions.map((spare) {
                final name = (spare['partname'] ?? spare['name'] ?? '')
                    .toString();
                final partNumber = spare['partnumber']?.toString() ?? '';
                final stock = _isEditMode && _selectedSpareId == null
                    ? _stockForSpareId(spare['id'] as int? ?? -1)
                    : <String, dynamic>{};
                final subtitle = _isEditMode
                    ? [
                        "Part No: $partNumber",
                        "MRP: ${_fieldValue(stock['mrp'])}",
                        "Purchase Rate: ${_fieldValue(stock['purchase_amount'])}",
                        "Qty: ${_fieldValue(stock['quantity'])}",
                      ].join("  |  ")
                    : partNumber;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.build_circle_outlined),
                  title: Text(name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  onTap: () => _selectSpare(spare),
                );
              }).toList(),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _modeSelector(ThemeData theme) {
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _totalBox(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Total purchase value: Rs ${_totalPurchase.toStringAsFixed(2)}",
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
