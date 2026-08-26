import 'package:intl/intl.dart';

/// Hilfsfunktionen für CHF-Geldbeträge. Beträge werden intern als
/// ganzzahlige Rappen gehalten, um Gleitkomma-Rundungsfehler bei
/// Rechnungsberechnungen zu vermeiden.
class Money {
  Money._();

  static final NumberFormat _chfFormat = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
  );

  /// Wandelt eine Benutzereingabe wie „120.50“ oder „120,50“ in Rappen um.
  /// Gibt `null` zurück, wenn die Eingabe keine gültige, nicht-negative Zahl
  /// ist.
  static int? parseChfToRappen(String input) {
    final normalized = input.trim().replaceAll("'", '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  static double rappenToChf(int rappen) => rappen / 100;

  /// Formatiert Rappen im Schweizer CHF-Format, z.B. „CHF 1'240.00“.
  static String formatRappen(int rappen) =>
      _chfFormat.format(rappenToChf(rappen));
}
