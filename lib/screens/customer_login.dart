import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/cubit/login/login_state.dart';
import 'package:digiauto/screens/home.dart';
import 'package:digiauto/screens/register.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerLogin extends StatefulWidget {
  CustomerLogin({super.key});

  @override
  State<CustomerLogin> createState() => CustomerLoginState();
}

class CustomerLoginState extends State<CustomerLogin> {
  final vehicleNumberController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Scaffold(
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
                          keyboardType: TextInputType.text,
                          controller: vehicleNumberController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Vehicle Number",
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
                        ),

                        const SizedBox(height: 30),

                        // 🔹 Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (vehicleNumberController.text.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(
                                      style: TextStyle(color: Colors.white),
                                      'Please enter a valid Vehicle Number...!',
                                    ),
                                  ),
                                );
                              }
                              // TODO: Implement your login logic

                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRout
                              //     builder: (_) => HomeScreen(),
                              //   ),s
                              // );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: const Text(
                              "Submit",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
    );
  }
}
