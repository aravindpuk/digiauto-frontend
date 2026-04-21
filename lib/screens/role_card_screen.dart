import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/cubit/login/login_state.dart';
import 'package:digiauto/screens/customer_login.dart';
import 'package:digiauto/screens/home.dart';
import 'package:digiauto/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => RoleSelectionState();
}

class RoleSelectionState extends State<RoleSelectionScreen> {
  dynamic primaryColor;
  dynamic secondaryColor;
  dynamic textColor;

  @override
  void initState() {
    super.initState();

    context.read<LoginCubit>().isUserLogedIn();
  }

  @override
  Widget build(BuildContext context) {
    primaryColor = Theme.of(context).primaryColor;
    secondaryColor = Theme.of(context).colorScheme.secondary;
    textColor = Theme.of(context).colorScheme.onSecondary;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraint) {
              bool isDesktop = constraint.maxWidth > 700;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color.fromARGB(255, 240, 229, 229),
                          primaryColor,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        children: [
                          // 🔹 Logo
                          Padding(
                            padding: EdgeInsetsGeometry.only(left: 10, top: 90),
                            child: Image.asset(
                              'assets/digiauto_logo.png',
                              width: 200,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Welcome to DigiAuto",
                            style: TextStyle(
                              fontSize: 18,
                              color: primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // 🔹 Vertical Customer Card
                          isDesktop
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildRoleCard(
                                        context,
                                        title: "I AM A CUSTOMER",
                                        description:
                                            "View your vehicle job cards & dashboards instantly without login.",
                                        buttonText: "CONTINUE AS CUSTOMER",
                                        icon:
                                            Icons.directions_car_filled_rounded,

                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CustomerLogin(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildRoleCard(
                                        context,
                                        title: "I AM A GARAGE",
                                        description:
                                            "Manage bookings, create service records, and grow your business.",
                                        buttonText: "LOG IN TO GARAGE PORTAL",
                                        icon: Icons.car_repair,

                                        buttonColor: secondaryColor,
                                        onPressed: () {
                                          // 🔹 Navigates to your existing LoginScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildRoleCard(
                                      context,
                                      title: "I AM A CUSTOMER",
                                      description:
                                          "View your vehicle job cards & dashboards instantly without login.",
                                      buttonText: "CONTINUE AS CUSTOMER",
                                      icon: Icons.directions_car_filled_rounded,

                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CustomerLogin(),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // 🔹 Vertical Garage Card
                                    _buildRoleCard(
                                      context,
                                      title: "I AM A GARAGE",
                                      description:
                                          "Manage bookings, create service records, and grow your business.",
                                      buttonText: "LOG IN TO GARAGE PORTAL",
                                      icon: Icons.car_repair,

                                      buttonColor: secondaryColor,
                                      onPressed: () {
                                        // 🔹 Navigates to your existing LoginScreen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LoginScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                          // Text(
                          //   "Learn more about DigiAuto",
                          //   style: TextStyle(
                          //     color: primaryColor,
                          //     fontSize: 13,
                          //     decoration: TextDecoration.underline,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    // required Color cardColor,
    Color? buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 234, 234),
        borderRadius: BorderRadius.circular(24),
        // boxShadow: [
        //   BoxShadow(
        //     // color: cardColor.withOpacity(0.3),
        //     blurRadius: 4,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: const Color.fromARGB(255, 186, 184, 184),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: primaryColor, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
