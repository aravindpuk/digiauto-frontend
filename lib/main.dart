// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'DigiAuto',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: const Color(0xFF2E7BA6),
//         scaffoldBackgroundColor: const Color(0xFFF8F9FA),
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF2E7BA6),
//           primary: const Color(0xFF2E7BA6),
//           secondary: const Color(0xFFFF5733),
//         ),
//       ),
//      home:const SplashScreen(),
//     );
//   }
// }

import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// make sure you have this file

void main() {
  runApp(const MyApp());
} // closes main

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiAuto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7BA6),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7BA6),
          primary: const Color(0xFF2E7BA6),
          secondary: const Color(0xFFFF5733),
          onSecondary: Colors.white,
        ),

        textTheme: TextTheme(
          bodyLarge: TextStyle(color: const Color(0xFF2E7BA6)),
          bodySmall: TextStyle(color: Color(0xFF7F8C8D)),
          titleLarge: TextStyle(
            color: Color(0xFF2E7BA6),
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7BA6),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ), //closes themedata
      home: BlocProvider(
        create: (BuildContext context) {
          return LoginCubit(AuthService());
        },
        child: LoginScreen(),
      ),
    ); //closes materialapp
  } //closes vuild
} // closes class
