import 'package:digiauto/custom_widgets/loading_button.dart';
import 'package:digiauto/screens/customer_home.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerLogin extends StatefulWidget {
  const CustomerLogin({super.key});

  @override
  State<CustomerLogin> createState() => CustomerLoginState();
}

class CustomerLoginState extends State<CustomerLogin> {
  final vehicleNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final job = await JobcardService().fetchLatestCustomerJob(
        vehicleNumberController.text,
      );
      if (!mounted) return;
      if (job == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('No job card found for this vehicle number.'),
          ),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CustomerHomeScreen(job: job)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, primaryColor],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/digiauto_logo.png', width: 200),
                            const SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(66, 1, 77, 96),
                                    blurRadius: 10,
                                    spreadRadius: 4,
                                    offset: Offset(-4, 4),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Login',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Enter your vehicle number to view its latest job card.',
                                      style: TextStyle(
                                        color: Color(0xFF667985),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    TextFormField(
                                      controller: vehicleNumberController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z0-9 -]'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        labelText: 'Vehicle Number',
                                        hintText: 'KL 07 AB 1234',
                                        prefixIcon: Icon(
                                          Icons.directions_car_outlined,
                                          color: secondaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        final normalized = (value ?? '')
                                            .replaceAll(
                                              RegExp(r'[^a-zA-Z0-9]'),
                                              '',
                                            );
                                        if (normalized.length < 5) {
                                          return 'Enter a valid vehicle number';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _login(),
                                    ),
                                    const SizedBox(height: 24),
                                    LoadingButton(
                                      label: 'Login',
                                      isLoading: _isLoading,
                                      onPressed: _login,
                                      backgroundColor: secondaryColor,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
