import 'package:digiauto/cubit/login/login_cubit.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
// make sure you have this file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (_) => LoginCubit(AuthService()))],
      child: const MyApp(),
    ),
  );
} // closes main

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiAuto',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
      home: LoginScreen(),
    ); //closes materialapp
  } //closes vuild
} // closes class
