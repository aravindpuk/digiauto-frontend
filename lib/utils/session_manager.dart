import 'package:digiauto/main.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:flutter/material.dart';

class SessionManager {
  static bool _showing = false;

  static void handleExpiredSession() {
    final context = navigatorKey.currentContext;
    if (context == null || _showing) return;
    _showing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Session Expired"),
        content: const Text(
          "Your login session has expired. Please log in again.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await clearSession();
              _showing = false;
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
