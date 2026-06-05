import 'package:digiauto/cubit/garage/garage_cubit.dart';
import 'package:digiauto/cubit/garage/garage_state.dart';
import 'package:digiauto/custom_widgets/scaffold_messenger.dart';
import 'package:digiauto/custom_widgets/loading_button.dart';
import 'package:digiauto/screens/home.dart';
import 'package:digiauto/screens/maps.dart';
import 'package:digiauto/services/garage_service.dart';
import 'package:digiauto/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GarageProvider extends StatelessWidget {
  const GarageProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GarageCubit(GarageService()),
      child: const GarageScreen(),
    );
  }
}

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  // Controller lives here so it persists across rebuilds
  final TextEditingController _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<GarageCubit, GarageState>(
      listener: (context, state) {
        if (state is GarageSuccessState) {
          showSnackBar(context, state.message, SnackType.success);
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        }
        if (state is GarageFailureState) {
          showSnackBar(context, state.message, SnackType.error);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              // Ensure the container is tall enough to scroll
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, primaryColor],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 120, top: 40),
                    child: Image.asset('assets/digiauto_logo.png', width: 200),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.only(top: 32, bottom: 32),
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(66, 1, 77, 96),
                            blurRadius: 10,
                            spreadRadius: 12,
                            offset: Offset(-8, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Register Garage",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 32),

                          // Garage Name
                          TextField(
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              label: _requiredLabel("Garage Name"),
                              enabledBorder: _border(primaryColor),
                              focusedBorder: _focusBorder(primaryColor),
                              prefixIcon: Icon(
                                Icons.garage_outlined,
                                color: secondaryColor,
                              ),
                            ),
                            onChanged: (v) =>
                                context.read<GarageCubit>().garageUpdate(v),
                          ),
                          const SizedBox(height: 20),

                          // Mobile
                          TextField(
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              label: _requiredLabel("Mobile Number"),
                              enabledBorder: _border(primaryColor),
                              focusedBorder: _focusBorder(primaryColor),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: secondaryColor,
                              ),
                            ),
                            onChanged: (v) =>
                                context.read<GarageCubit>().mobileUpdate(v),
                          ),
                          const SizedBox(height: 20),

                          // Email (optional)
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Email Id (optional)",
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              enabledBorder: _border(primaryColor),
                              focusedBorder: _focusBorder(primaryColor),
                              prefixIcon: Icon(
                                Icons.email,
                                color: secondaryColor,
                              ),
                            ),
                            onChanged: (v) =>
                                context.read<GarageCubit>().emailUpdate(v),
                          ),
                          const SizedBox(height: 20),

                          // Location (read-only, filled from map picker)
                          TextField(
                            controller: _locationCtrl,
                            readOnly: true,
                            onTap: () => _pickLocation(context),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              label: _requiredLabel("Location"),
                              enabledBorder: _border(primaryColor),
                              focusedBorder: _focusBorder(primaryColor),
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.location_on),
                                color: secondaryColor,
                                onPressed: () => _pickLocation(context),
                              ),
                              suffixIcon: const Icon(Icons.chevron_right),
                              hintText: "Tap to search and pick location",
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Register button — driven by state.isValid
                          BlocBuilder<GarageCubit, GarageState>(
                            builder: (context, state) {
                              return LoadingButton(
                                label: "Register",
                                isLoading: state.isLoading,
                                onPressed: state.isValid
                                    ? () => context
                                          .read<GarageCubit>()
                                          .registerGarage()
                                    : null,
                                backgroundColor: secondaryColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickLocation(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );

    if (!mounted || result == null) return;
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    final name = result['name']?.toString().trim() ?? '';

    context.read<GarageCubit>().locationUpdate(lat: lat, lng: lng);

    setState(() {
      _locationCtrl.text = name.isNotEmpty
          ? name
          : "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
    });
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderSide: BorderSide(color: color),
    borderRadius: BorderRadius.circular(12),
  );

  OutlineInputBorder _focusBorder(Color color) => OutlineInputBorder(
    borderSide: BorderSide(color: color, width: 2),
    borderRadius: BorderRadius.circular(12),
  );
}
