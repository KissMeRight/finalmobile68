import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF6C63FF); // purple
  static const Color secondary = Color(0xFF03DAC6); // teal
  static const Color blue = Color(0xFF2196F3);
  static const Color green = Color(0xFF4CAF50);
  static const Color amber = Color(0xFFFF9800);
  static const Color red = Color(0xFFE53935);

  // Slot colors
  static const Color blueSlot = Color(0xFF1565C0);
  static const Color greenSlot = Color(0xFF2E7D32);

  // Background
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgCard = Color(0xFF161B22);
  static const Color bgSurface = Color(0xFF21262D);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: bgCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardTheme(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12),
    ),
  );
}

// Status badge colors
extension StatusColor on String {
  Color get statusColor {
    switch (toLowerCase()) {
      case 'running':
      case 'ready':
      case 'success':
      case 'active':
        return AppTheme.green;
      case 'pending':
      case 'building':
      case 'in_progress':
        return AppTheme.amber;
      case 'failed':
      case 'error':
      case 'exited':
        return AppTheme.red;
      default:
        return AppTheme.textSecondary;
    }
  }
}
