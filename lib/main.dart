import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/screens/role_card_screen.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// make sure you have this file

void main() {
  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (_) => LoginCubit(AuthService()))],
      child: const MyApp(),
    ),
  );
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
      home: RoleSelectionScreen(),
    ); //closes materialapp
  } //closes vuild
} // closes class
