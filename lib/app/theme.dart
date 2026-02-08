import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème bleu professionnel pour l'application HSE (police Poppins).
class AppTheme {
  AppTheme._();

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _primaryLight = Color(0xFF42A5F5);
  static const Color _surface = Color(0xFFF5F9FF);
  static const Color _error = Color(0xFFB71C1C);
  static const Color _warning = Color(0xFFE65100);
  static const Color _success = Color(0xFF2E7D32);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.light(
        primary: _primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: _primaryLight.withValues(alpha: 0.3),
        onPrimaryContainer: _primaryDark,
        secondary: _primaryLight,
        onSecondary: Colors.white,
        surface: _surface,
        onSurface: const Color(0xFF1A1A2E),
        error: _error,
        onError: Colors.white,
        outline: _primaryBlue.withValues(alpha: 0.5),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryBlue.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerColor: _primaryBlue.withValues(alpha: 0.2),
    );
  }

  /// Couleur pour seuil critique (stock)
  static Color get criticalColor => _warning;

  /// Couleur pour état OK
  static Color get okColor => _success;

  /// Couleur pour gravité incident (1-5)
  static Color severityColor(int gravite) {
    if (gravite <= 1) return _success;
    if (gravite <= 2) return Colors.orange;
    if (gravite <= 3) return _warning;
    if (gravite <= 4) return Colors.deepOrange;
    return _error;
  }
}
