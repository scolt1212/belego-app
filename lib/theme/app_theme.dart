import 'package:flutter/material.dart';

/// Belego Farbpalette – babyblauer Akzent (Tailwind sky-500/600)
/// auf weiss/grauem Hintergrund.
class AppColors {
  AppColors._();

  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky600 = Color(0xFF0284C7);

  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB); // gray-200

  /// Deutlich sichtbare Umrandung für interaktive Eingabefelder (Text,
  /// Dropdown, Datum) – bewusst etwas kräftiger als [border], das für
  /// Karten/Trennlinien verwendet wird. Immer sichtbar, auch ohne Fokus.
  static const Color fieldBorder = Color(0xFFCBD5E1); // slate-300

  /// Sehr heller blaugrauer Hintergrund für editierbare Felder, damit sie
  /// bereits ohne Fokus klar als Eingabefeld erkennbar sind (bewusst weder
  /// reines Weiss noch identisch mit dem Seitenhintergrund).
  static const Color fieldFill = Color(0xFFF1F5F9); // slate-100

  /// Dezenter Hintergrund für automatisch berechnete/vergebene Felder
  /// (z.B. Rechnungsnummer, Fälligkeitsdatum), damit sie sich klar von
  /// editierbaren Feldern unterscheiden.
  static const Color autoFieldFill = Color(0xFFF3F4F6); // gray-100

  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500

  static const Color danger = Color(0xFFDC2626); // red-600
  static const Color dangerBg = Color(0xFFFEF2F2); // red-50
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.sky500,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.sky600,
          secondary: AppColors.sky500,
          surface: AppColors.surface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.sky600,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.sky600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        helperStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.fieldBorder,
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.fieldBorder,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.fieldBorder,
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sky600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sky600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sky600,
          side: const BorderSide(color: AppColors.sky600),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.sky600),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.sky600,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}
