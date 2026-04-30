import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFD4537E);
  static const Color primaryLight = Color(0xFFED93B1);
  static const Color primaryDark = Color(0xFF993556);
  static const Color accent = Color(0xFFF4A261);
  static const Color bgLight = Color(0xFFFFF5F8);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF4B1528);
  static const Color textSecondary = Color(0xFF993556);
  static const Color textHint = Color(0xFFD4A0B0);
  static const Color border = Color(0xFFF4C0D1);
  static const Color success = Color(0xFF40916C);
  static const Color warning = Color(0xFFFFB703);
  static const Color error = Color(0xFFE63946);
  static const Color info = Color(0xFF457B9D);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
        ),
        scaffoldBackgroundColor: bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD4537E),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bgCard,
          selectedItemColor: Color(0xFFD4537E),
          unselectedItemColor: Color(0xFFD4A0B0),
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
