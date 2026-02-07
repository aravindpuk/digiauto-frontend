import 'package:digiauto/screens/garage.dart';
import 'package:digiauto/screens/login.dart';
import 'package:flutter/material.dart';

class UserRegister extends StatelessWidget {
  const UserRegister({super.key});

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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 120, top: 40),
                  child: Image.asset('assets/digiauto_logo.png', width: 200),
                ),
                // 🔹 Logo at top-left
                // Positioned(
                //   top: 60,
                //   left: 30,
                //   child: Hero(
                //     tag: 'logo',
                //     child: Image.asset('assets/digiauto_logo.png', width: 200),
                //   ),
                // ),

                // 🔹 Curved container on right side
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: EdgeInsets.only(top: 52.0),
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.68,
                    decoration: const BoxDecoration(
                      // color: Colors.white,
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      // BorderRadius.only(
                      //   topLeft: Radius.circular(60),
                      //   bottomLeft: Radius.circular(60),
                      // ),
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
                          "Register",

                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 40),
                        // user name
                        TextField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Name",
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
                              Icons.person_2_rounded,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Mobile Number
                        TextField(
                          keyboardType: TextInputType.phone,
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
                        ),

                        const SizedBox(height: 20),

                        // 🔹 4-digit PIN
                        TextField(
                          obscureText: true,
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
                            prefixIcon: Icon(Icons.lock, color: secondaryColor),
                          ),
                        ),

                        // const SizedBox(height: 20.0),
                        // //user role
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     Expanded(
                        //       child: RadioListTile<String>(
                        //         value: "admin",
                        //         // groupValue: selectedRole,
                        //         title: const Text("Admin"),
                        //         dense: true,
                        //         contentPadding: EdgeInsets.zero,
                        //         // onChanged: (value) =>
                        //         //     setState(() => selectedRole = value),
                        //       ),
                        //     ),
                        //     Expanded(
                        //       child: RadioListTile<String>(
                        //         value: "customer",
                        //         // groupValue: selectedRole,
                        //         title: const Text("Customer"),
                        //         dense: true,
                        //         contentPadding: EdgeInsets.zero,
                        //         // onChanged: (value) =>
                        //         //     setState(() => selectedRole = value),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 30),

                        // 🔹 Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement your login logic
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GarageScreen(),
                                ),
                              );
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
                              "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "have an account? ",
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
                                    builder: (_) => LoginScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Log In',
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
    );
  }
}
