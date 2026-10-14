import 'dart:typed_data';

import 'package:digiauto/services/spare_shop_service.dart';
import 'package:digiauto/services/vehicle_catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SpareShopInventoryForm extends StatefulWidget {
  const SpareShopInventoryForm({
    super.key,
    required this.service,
    required this.item,
    required this.onSaved,
  });
  final SpareShopService service;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  @override
  State<SpareShopInventoryForm> createState() => _SpareShopInventoryFormState();
}

class _SpareShopInventoryFormState extends State<SpareShopInventoryForm> {
  static const _blue = Color(0xFF1769AA);
  static const _ink = Color(0xFF18364C);
  static const _muted = Color(0xFF738398);
  final _catalog = VehicleCatalogService();
  final _picker = ImagePicker();
  final _year = TextEditingController();
  final _name = TextEditingController();
  final _mrp = TextEditingController();
  List<Map<String, dynamic>> _makes = [];
  Map<String, dynamic>? _make;
  Map<String, dynamic>? _model;
  List<XFile> _newImages = [];
  List<Uint8List> _previews = [];
  List<Map<String, dynamic>> _existingImages = [];
  final Set<int> _removedImageIds = {};
  bool _loadingCatalog = true;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _year.text = (widget.item?['vehicle_year'] ?? '').toString();
    _name.text = (widget.item?['spare_name'] ?? '').toString();
    _mrp.text = (widget.item?['mrp'] ?? '').toString();
    _existingImages = ((widget.item?['images'] as List?) ?? const [])
        .whereType<Map>()
        .map((image) => Map<String, dynamic>.from(image))
        .toList();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final makes = await _catalog.fetchMakes();
      if (!mounted) return;
      Map<String, dynamic>? make;
      Map<String, dynamic>? model;
      final item = widget.item;
      if (item != null) {
        for (final candidate in makes) {
          if ((candidate['name'] ?? '').toString().toLowerCase() ==
              (item['vehicle_make'] ?? '').toString().toLowerCase()) {
            make = candidate;
            final models =
                (candidate['models'] as List?)?.whereType<Map>() ?? const [];
            for (final entry in models) {
              if ((entry['id'] ?? '').toString() ==
                  (item['vehicle_model_id'] ?? '').toString()) {
                model = Map<String, dynamic>.from(entry);
                break;
              }
            }
            break;
          }
        }
      }
      setState(() {
        _makes = makes;
        _make = make;
        _model = model;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _year.dispose();
    _name.dispose();
    _mrp.dispose();
    super.dispose();
  }

  Future<void> _chooseImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Add spare photos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(
          imageQuality: 82,
          maxWidth: 1600,
          maxHeight: 1600,
        );
      } else {
        final image = await _picker.pickImage(
          source: source,
          imageQuality: 82,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        picked = image == null ? <XFile>[] : <XFile>[image];
      }
      if (picked.isEmpty) return;
      final room =
          6 -
          _existingImages
              .where((e) => !_removedImageIds.contains(e['id']))
              .length -
          _newImages.length;
      final accepted = <XFile>[];
      final previews = <Uint8List>[];
      for (final image in picked.take(room.clamp(0, 6).toInt())) {
        final bytes = await image.readAsBytes();
        if (bytes.length <= 5 * 1024 * 1024) {
          accepted.add(image);
          previews.add(bytes);
        }
      }
      if (!mounted) return;
      setState(() {
        _newImages = [..._newImages, ...accepted];
        _previews = [..._previews, ...previews];
      });
      if (accepted.length < picked.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Up to 6 photos are allowed, each up to 5 MB.'),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the camera or gallery.'),
          ),
        );
    }
  }

  Future<void> _save() async {
    if (_make == null || _model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose a vehicle make and model from the suggestions.',
          ),
        ),
      );
      return;
    }
    if (_name.text.trim().isEmpty || _mrp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spare name and MRP are required.')),
      );
      return;
    }
    if (!_isEditing && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one spare photo.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.saveInventory(
        itemId: widget.item?['id'] as int?,
        vehicleModelId: _model!['id'] as int,
        vehicleYear: _year.text,
        spareName: _name.text,
        mrp: _mrp.text,
        images: _newImages,
        removeImageIds: _removedImageIds.toList(),
      );
      if (mounted) widget.onSaved();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          _isEditing ? 'Edit spare' : 'Add a spare',
          style: const TextStyle(
            color: _ink,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _isEditing
              ? 'Update fitment, price and photos.'
              : 'List a used part for DigiAuto customers.',
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 18),
        _card(
          title: 'Vehicle fitment',
          icon: Icons.directions_car_outlined,
          children: [
            if (_loadingCatalog)
              const LinearProgressIndicator(minHeight: 2)
            else if (_makes.isEmpty)
              const Text(
                'Vehicle catalog could not be loaded. Check your connection and retry.',
                style: TextStyle(color: _muted),
              ),
            _catalogField<Map<String, dynamic>>(
              key: ValueKey(
                'make-${widget.item?['id'] ?? 'new'}-$_loadingCatalog',
              ),
              label: 'Vehicle make',
              icon: Icons.factory_outlined,
              initial: _make,
              options: (query) => _makes.where(
                (entry) => (entry['name'] as String).toLowerCase().contains(
                  query.toLowerCase(),
                ),
              ),
              onTextChanged: (text) {
                if (_make != null &&
                    _make!['name'].toString().toLowerCase() !=
                        text.trim().toLowerCase()) {
                  setState(() {
                    _make = null;
                    _model = null;
                  });
                }
              },
              onSelected: (value) => setState(() {
                _make = value;
                _model = null;
              }),
            ),
            const SizedBox(height: 13),
            _catalogField<Map<String, dynamic>>(
              key: ValueKey(
                'model-${widget.item?['id'] ?? 'new'}-${_make?['id']}-$_loadingCatalog',
              ),
              label: 'Vehicle model',
              icon: Icons.directions_car_filled_outlined,
              initial: _model,
              enabled: _make != null,
              options: (query) =>
                  ((_make?['models'] as List?)?.whereType<Map>().map(
                            (e) => Map<String, dynamic>.from(e),
                          ) ??
                          const <Map<String, dynamic>>[])
                      .where(
                        (entry) => (entry['name'] as String)
                            .toLowerCase()
                            .contains(query.toLowerCase()),
                      ),
              onTextChanged: (text) {
                if (_model != null &&
                    _model!['name'].toString().toLowerCase() !=
                        text.trim().toLowerCase()) {
                  setState(() => _model = null);
                }
              },
              onSelected: (value) => setState(() => _model = value),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: _decoration(
                'Manufacture year (optional)',
                Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _card(
          title: 'Spare details',
          icon: Icons.settings_outlined,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(
                'Spare name',
                Icons.build_outlined,
                hint: 'e.g. Gear box',
              ),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _mrp,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: _decoration(
                'MRP (₹)',
                Icons.currency_rupee_rounded,
                hint: 'e.g. 18500',
              ),
            ),
            const SizedBox(height: 14),
            _photos(),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
          label: Text(
            _saving
                ? 'Saving…'
                : _isEditing
                ? 'Save changes'
                : 'Add to inventory',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _catalogField<T extends Map<String, dynamic>>({
    Key? key,
    required String label,
    required IconData icon,
    required Iterable<T> Function(String) options,
    required ValueChanged<T> onSelected,
    required ValueChanged<String> onTextChanged,
    T? initial,
    bool enabled = true,
  }) => Autocomplete<T>(
    key: key,
    initialValue: TextEditingValue(text: (initial?['name'] ?? '').toString()),
    displayStringForOption: (option) => option['name'].toString(),
    optionsBuilder: (value) => !enabled || value.text.trim().isEmpty
        ? const Iterable.empty()
        : options(value.text.trim()).take(12),
    onSelected: onSelected,
    fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onTextChanged,
      decoration: _decoration(
        label,
        icon,
        hint: enabled ? 'Search and select $label' : 'Select a make first',
      ),
    ),
    optionsViewBuilder: (context, select, values) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: values
                .map(
                  (value) => ListTile(
                    title: Text(value['name'].toString()),
                    onTap: () => select(value),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );

  Widget _photos() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Photos',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${_existingImages.length - _removedImageIds.length + _previews.length}/6',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 9),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          for (final image in _existingImages)
            if (!_removedImageIds.contains(image['id']))
              _photoTile(
                Image.network(
                  image['url'].toString(),
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
                () => setState(() => _removedImageIds.add(image['id'] as int)),
              ),
          for (var i = 0; i < _previews.length; i++)
            _photoTile(
              Image.memory(
                _previews[i],
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              ),
              () => setState(() {
                _previews.removeAt(i);
                _newImages.removeAt(i);
              }),
            ),
          if (_existingImages.length -
                  _removedImageIds.length +
                  _previews.length <
              6)
            InkWell(
              onTap: _chooseImages,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE7EF)),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: _blue),
              ),
            ),
        ],
      ),
      const SizedBox(height: 7),
      const Text(
        'Add clear photos of the spare. Up to 6 images, 5 MB each.',
        style: TextStyle(color: _muted, fontSize: 11),
      ),
    ],
  );

  Widget _photoTile(Widget image, VoidCallback remove) => Stack(
    clipBehavior: Clip.none,
    children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
      Positioned(
        right: -5,
        top: -5,
        child: InkWell(
          onTap: remove,
          child: Container(
            width: 23,
            height: 23,
            decoration: const BoxDecoration(
              color: Color(0xFFAA5149),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 15, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _placeholder() => Container(
    width: 78,
    height: 78,
    color: const Color(0xFFEAF2F8),
    child: const Icon(Icons.broken_image_outlined, color: _muted),
  );

  InputDecoration _decoration(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _blue),
        filled: true,
        fillColor: const Color(0xFFFBFCFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E8EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E8EE)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5ECF1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _blue, size: 20),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...children,
      ],
    ),
  );
}
