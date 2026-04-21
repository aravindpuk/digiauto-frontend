import 'package:digiauto/utils/enums.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, SnackType type) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: Colors.white)),
      backgroundColor: type == SnackType.error ? Colors.red : Colors.green[800],
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    ),
  );
}
