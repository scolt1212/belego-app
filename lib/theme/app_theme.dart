import 'package:flutter/material.dart';

/// Belego Farbpalette – modernes Weiss/Hellblau als Grundlage, kräftiges
/// Belego-Blau als durchgehender Hauptakzent. Orange markiert private
/// Termine/Aufgaben, Grün steht für Bezahlt/Erledigt, Rot für Fehler und
/// überfällige Rechnungen, Grau für Entwurf/keine Kategorie – siehe
/// CLAUDE.md. Wichtig: dieses Farbsystem gilt nur für die App-Oberfläche.
/// Die Rechnungs-Vorschau (künftig PDF) bleibt bewusst neutral in
/// Schwarz/Weiss/Grau, siehe `InvoicePreviewScreen`.
class AppColors {
  AppColors._();

  /// Kräftiges, klares Belego-Blau – der einzige durchgehende Hauptakzent.
  static const Color sky500 = Color(0xFF0878F9);
  static const Color sky600 = Color(0xFF0878F9);

  /// Helles Blau für Tints, Badges und Eingabefeld-Hintergründe.
  static const Color sky100 = Color(0xFFEAF4FF);

  /// Sehr helles Hintergrundblau – Basis des Seitenhintergrunds.
  static const Color sky50 = Color(0xFFF6FAFF);

  /// Allgemeiner Seitenhintergrund.
  static const Color background = Color(0xFFF6FAFF);

  /// Kartenhintergrund – reines Weiss, hebt Karten vom Seitenhintergrund ab.
  static const Color surface = Colors.white;

  /// Kartenrahmen – fein sichtbar, aber dezent.
  static const Color border = Color(0xFFDCE6F2);

  /// Umrandung für interaktive Eingabefelder. Immer sichtbar, auch ohne
  /// Fokus.
  static const Color fieldBorder = Color(0xFFDCE6F2);

  /// Leicht hellblauer Hintergrund für editierbare Felder, damit sie bereits
  /// ohne Fokus klar als Eingabefeld erkennbar sind.
  static const Color fieldFill = Color(0xFFEAF4FF);

  /// Dezenter, neutral-grauer Hintergrund für automatisch berechnete/
  /// vergebene Felder (z.B. Rechnungsnummer, Fälligkeitsdatum) – bewusst
  /// NICHT blau, damit sie sich klar von editierbaren Feldern unterscheiden.
  static const Color autoFieldFill = Color(0xFFF1F3F6);

  /// Haupttext – dunkles Navy statt reinem Schwarz.
  static const Color textPrimary = Color(0xFF071B49);

  /// Sekundärtext – graublau.
  static const Color textSecondary = Color(0xFF65738B);

  /// Fehler/überfällig – zurückhaltendes Rot.
  static const Color danger = Color(0xFFE45454);
  static const Color dangerBg = Color(0xFFFCEBEB);

  /// Kategorie „Geschäftlich“ (Termine/Aufgaben) – identisch mit dem
  /// Hauptakzent.
  static const Color businessBlue = sky500;

  /// Kategorie „Privat“ (Termine/Aufgaben).
  static const Color privateOrange = Color(0xFFF59E0B);
  static const Color privateOrangeBg = Color(0xFFFEF3E0);

  /// Status „Bezahlt“/„Erledigt“ – Grün bleibt ausschliesslich dafür
  /// reserviert (nicht für „Privat“).
  static const Color paidGreen = Color(0xFF20B66A);
  static const Color paidGreenBg = Color(0xFFE7F8EF);

  /// Status „Entwurf“ bzw. „keine Kategorie“ – neutrales Grau.
  static const Color draftGrey = Color(0xFF8490A4);
  static const Color draftGreyBg = Color(0xFFEEF1F4);

  /// Zweiter, minimal kräftigerer Wellenton für den organischen
  /// Seitenhintergrund der „Heute“-Seite (siehe `HeroBackground`).
  static const Color waveSecondary = Color(0xFFDCEEFF);
}

/// Wiederverwendbarer weicher Kartenschatten für hervorgehobene Flächen auf
/// der „Heute“-Seite (Finanzkarten, Diagramm, Kalender, Aufgaben,
/// Schnellaktionen, schwebende Navigation) – bewusst zusätzlich zum
/// `cardTheme`-Rahmen, nicht als globale Elevation, damit andere Screens
/// (Rechnungseditor, Dokumente, Firmeneinrichtung) unverändert bleiben.
class AppShadows {
  AppShadows._();

  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Zentrale Abstandswerte, u.a. für die Startseite. Bildet zusammen mit
/// [AppColors] die Grundlage, um später z.B. eine wählbare Akzentfarbe zu
/// ergänzen, ohne Werte in jedem Widget einzeln anpassen zu müssen.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 32;
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
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      // Die eigentliche schwebende Navigationskarte wird in `RootShell`
      // selbst gezeichnet (weisse Karte mit Schatten und Rand-Abstand);
      // dieses Theme steuert nur Farben/Typografie der `NavigationBar`
      // darin.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.sky100,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.sky600 : AppColors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.sky600 : AppColors.textSecondary,
          );
        }),
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
