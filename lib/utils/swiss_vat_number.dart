/// Validierung und Formatierung der Schweizer Unternehmens-Identifikations-
/// nummer (UID) für MWST-Zwecke, Schema `CHE-123.456.789 MWST`.
///
/// Geprüft wird nur das Format (9 Ziffern nach „CHE“) – keine echte Abfrage
/// im UID-Register.
class SwissVatNumber {
  SwissVatNumber._();

  static const String errorMessage =
      'Bitte eine gültige MWST-Nummer eingeben, z.B. CHE-123.456.789 MWST.';

  /// Extrahiert die 9 Ziffern aus einer Eingabe wie `CHE-123.456.789 MWST`,
  /// `CHE123456789` oder `123456789`. Gibt `null` zurück, wenn keine 9
  /// zusammenhängenden Ziffern gefunden werden.
  static String? _extractDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 9) return null;
    return digits;
  }

  static bool isValid(String raw) => _extractDigits(raw) != null;

  static String? validate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Bitte MWST-Nummer eingeben';
    return _extractDigits(raw) == null ? errorMessage : null;
  }

  /// Formatiert für die Anzeige/Speicherung als `CHE-123.456.789 MWST`.
  /// Gibt die unveränderte Eingabe zurück, falls sie nicht auswertbar ist.
  static String formatForDisplay(String raw) {
    final digits = _extractDigits(raw);
    if (digits == null) return raw;
    return 'CHE-${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)} MWST';
  }
}
