import 'package:digiauto/screens/home.dart';
import 'package:flutter/material.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

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
                            labelText: "Garage Name",
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
                              Icons.garage_outlined,
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

                        // 🔹 Email id
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Email Id",
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
                              Icons.email,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        //location
                        TextField(
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            labelText: "Location",
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
                              Icons.place,
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
                              // TODO: Implement your login logic
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => HomeScreen()),
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
                              "Register",
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
