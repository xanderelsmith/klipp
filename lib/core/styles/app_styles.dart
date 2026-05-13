import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.red;
  static const Color background = Color(0xFF1A1A1A);
  static const Color sidebar = Color(0xFF252525);
  static const Color accent = Colors.redAccent;
  static const Color surface = Color(0xFF2D2D2D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color warning = Colors.amber;
  static const Color success = Colors.green;
}

class AppStyles {
  static const EdgeInsets pagePadding = EdgeInsets.all(32.0);
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
