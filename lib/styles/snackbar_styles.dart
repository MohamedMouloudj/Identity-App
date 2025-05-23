import 'package:flutter/material.dart';

enum SnackBarType { info, success, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
}) {
  Color backgroundColor;
  switch (type) {
    case SnackBarType.success:
      backgroundColor = Colors.green;
      break;
    case SnackBarType.error:
      backgroundColor = Colors.red;
      break;
    case SnackBarType.info:
    default:
      backgroundColor = Colors.orange;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
    ),
  );
}
