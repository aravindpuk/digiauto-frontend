import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/cubit/login/login_state.dart';
import 'package:digiauto/custom_widgets/scaffold_messenger.dart';
import 'package:digiauto/screens/garage.dart';
import 'package:digiauto/screens/home.dart';
import 'package:digiauto/screens/register.dart';
import 'package:digiauto/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor   = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginFailure) {
          showSnackBar(context, state.message, SnackType.error);
        }
        if (state is LoginSuccess) {
          // No garage yet → register garage first
          if (state.garageId == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GarageProvider()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, primaryColor],
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 90),
                    child: Image.asset('assets/digiauto_logo.png', width: 200),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width:  MediaQuery.of(context).size.width  * 0.85,
                      height: MediaQuery.of(context).size.height * 0.65,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft:    Radius.circular(60),
                          bottomLeft: Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:       Color.fromARGB(66, 1, 77, 96),
                            blurRadius:  10,
                            spreadRadius: 12,
                            offset:      Offset(-8, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Text(
                            "Login",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 40),

                          // Mobile
                          TextField(
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: _inputDecoration(
                              context,
                              label: "Mobile Number",
                              icon:  Icons.phone,
                              primaryColor:   primaryColor,
                              secondaryColor: secondaryColor,
                            ),
                            onChanged: (v) =>
                                context.read<LoginCubit>().mobileChanged(v),
                          ),
                          const SizedBox(height: 20),

                          // PIN
                          TextField(
                            obscureText: true,
                            maxLength:   4,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: _inputDecoration(
                              context,
                              label: "4-Digit PIN",
                              icon:  Icons.lock,
                              primaryColor:   primaryColor,
                              secondaryColor: secondaryColor,
                              counterText: "",
                            ),
                            onChanged: (v) =>
                                context.read<LoginCubit>().pinChanged(v),
                          ),
                          const SizedBox(height: 30),

                          // Button
                          BlocBuilder<LoginCubit, LoginState>(
                            builder: (context, state) {
                              if (state.isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: state.isValid
                                      ? () =>
                                          context.read<LoginCubit>().login()
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor,
                                    disabledBackgroundColor:
                                        secondaryColor.withOpacity(0.4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 6,
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? ",
                                  style: TextStyle(
                                      color: Color(0xFF7F8C8D),
                                      fontSize: 15)),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserProvider(
                                        role: userType.admin),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Sign Up',
                                    style: TextStyle(
                                        color: Color(0xFF2E7BA6),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
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

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    String? counterText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      counterText: counterText,
      labelStyle: Theme.of(context).textTheme.bodySmall,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: Icon(icon, color: secondaryColor),
    );
  }
}