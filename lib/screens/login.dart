import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/cubit/login/login_state.dart';
import 'package:digiauto/screens/home.dart';
import 'package:digiauto/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final mobileController = TextEditingController();
  final pinController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return BlocListener(
      listener: (context, state) {
        if (state is LoginFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is LoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
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
                  // 🔹 Logo at top-left
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 10, top: 90),
                    child: Image.asset('assets/digiauto_logo.png', width: 200),
                  ),

                  // 🔹 Curved container on right side
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.65,
                      decoration: const BoxDecoration(
                        // color: Colors.white,
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          bottomLeft: Radius.circular(60),
                        ),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Login",

                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 40),

                          // 🔹 Mobile Number
                          TextField(
                            keyboardType: TextInputType.phone,
                            controller: mobileController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Mobile Number",
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: secondaryColor,
                              ),
                            ),
                            onChanged: (_) {
                              context.read<LoginCubit>().onInputChanged(
                                mobileController.text,
                                pinController.text,
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // 🔹 4-digit PIN
                          TextField(
                            obscureText: true,
                            controller: pinController,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "4-Digit PIN",
                              counterText: "",
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: secondaryColor,
                              ),
                            ),
                            onChanged: (_) {
                              context.read<LoginCubit>().onInputChanged(
                                mobileController.text,
                                pinController.text,
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // 🔹 Login Button
                          SizedBox(
                            width: double.infinity,
                            child: BlocBuilder<LoginCubit, LoginState>(
                              builder: (context, state) {
                                bool enabled =
                                    state is LoginInitial &&
                                    state.loginBtnStatus == true;
                                if (state is LoginLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else {
                                  return ElevatedButton(
                                    onPressed: enabled
                                        ? () {
                                            // TODO: Implement your login logic

                                            context.read<LoginCubit>().login(
                                              mobileController.text,
                                              pinController.text,
                                            );
                                            // Navigator.pushReplacement(
                                            //   context,
                                            //   MaterialPageRoute(
                                            //     builder: (_) => HomeScreen(),
                                            //   ),s
                                            // );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: secondaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 6,
                                      shadowColor: primaryColor.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Sign Up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF7F8C8D),
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UserRegister(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFF2E7BA6),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
}
