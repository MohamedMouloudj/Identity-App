import 'package:flutter/material.dart';

ButtonStyle buildButtonStyle(Color color) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    foregroundColor: Colors.white,
  );
}
ButtonStyle primaryButtonStyle() => buildButtonStyle(const Color(0xFF1A237E));
