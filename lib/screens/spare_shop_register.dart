import 'package:digiauto/custom_widgets/loading_button.dart';
import 'package:digiauto/custom_widgets/scaffold_messenger.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/screens/maps.dart';
import 'package:digiauto/services/spare_shop_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:digiauto/utils/enums.dart';
import 'package:flutter/material.dart';

class SpareShopRegisterScreen extends StatefulWidget {
  const SpareShopRegisterScreen({super.key});

  @override
  State<SpareShopRegisterScreen> createState() =>
      _SpareShopRegisterScreenState();
}

class _SpareShopRegisterScreenState extends State<SpareShopRegisterScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _service = SpareShopService();
  double? _latitude;
  double? _longitude;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _latitude = result['lat'] as double;
      _longitude = result['lng'] as double;
      final place = result['name']?.toString().trim() ?? '';
      _locationController.text = place.isNotEmpty
          ? place
          : "${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}";
    });
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _latitude == null ||
        _longitude == null) {
      showSnackBar(
        context,
        'Enter the shop name and choose its location.',
        SnackType.error,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _service.register(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      if (result['status'] == 201) {
        showSnackBar(
          context,
          result['body']['message']?.toString() ?? 'Shop registered.',
          SnackType.success,
        );
        await clearSession();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        showSnackBar(
          context,
          result['body']['message']?.toString() ?? 'Shop registration failed.',
          SnackType.error,
        );
      }
    } catch (_) {
      if (mounted)
        showSnackBar(
          context,
          'Could not register the shop. Please try again.',
          SnackType.error,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('Register Spare Shop')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Spare shop name',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _locationController,
                    readOnly: true,
                    onTap: _pickLocation,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Tap to search and choose the shop location',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.location_on_outlined),
                        color: accent,
                        onPressed: _pickLocation,
                      ),
                      suffixIcon: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 28),
                  LoadingButton(
                    label: 'Register shop',
                    isLoading: _loading,
                    onPressed: _loading ? null : _register,
                    backgroundColor: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
