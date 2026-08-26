/// Validierung und Formatierung von IBANs, inkl. echter Prüfsummenprüfung
/// nach ISO 7064 (MOD 97-10) – nicht nur Länge/Länderkürzel.
class Iban {
  Iban._();

  static final RegExp _formatPattern = RegExp(r'^[A-Z]{2}[0-9A-Z]{13,32}$');

  /// Entfernt Leerzeichen und wandelt in Grossbuchstaben um.
  static String normalize(String raw) => raw.replaceAll(' ', '').toUpperCase();

  /// Grundlegende Formatprüfung plus echte Modulo-97-Prüfsummenprüfung.
  /// Gibt `null` zurück, wenn die IBAN gültig ist, sonst eine verständliche
  /// deutsche Fehlermeldung.
  static String? validate(String? value) {
    final cleaned = normalize(value ?? '');
    if (cleaned.isEmpty) return 'Bitte IBAN eingeben';
    if (!_formatPattern.hasMatch(cleaned)) {
      return 'Bitte eine gültige IBAN eingeben, z.B. CH93 0076 2011 6238 5295 7';
    }
    if (!_passesChecksum(cleaned)) {
      return 'Diese IBAN ist ungültig (Prüfsumme stimmt nicht).';
    }
    return null;
  }

  static bool isValid(String raw) {
    final cleaned = normalize(raw);
    return _formatPattern.hasMatch(cleaned) && _passesChecksum(cleaned);
  }

  /// ISO 7064 MOD 97-10: Die ersten 4 Zeichen ans Ende verschieben, Buchstaben
  /// in Zahlen umwandeln (A=10 … Z=35) und modulo 97 rechnen. Gültig, wenn
  /// der Rest 1 ergibt.
  static bool _passesChecksum(String cleanedIban) {
    final rearranged = cleanedIban.substring(4) + cleanedIban.substring(0, 4);
    final buffer = StringBuffer();
    for (final unit in rearranged.codeUnits) {
      if (unit >= 65 && unit <= 90) {
        buffer.write(unit - 55);
      } else {
        buffer.write(String.fromCharCode(unit));
      }
    }
    final numeric = BigInt.tryParse(buffer.toString());
    if (numeric == null) return false;
    return numeric % BigInt.from(97) == BigInt.one;
  }

  /// Formatiert eine IBAN für die Anzeige in 4er-Gruppen, z.B.
  /// „CH93 0076 2011 6238 5295 7“. Der gespeicherte Wert bleibt unverändert.
  static String formatForDisplay(String iban) {
    final cleaned = normalize(iban);
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(
        cleaned.substring(i, i + 4 > cleaned.length ? cleaned.length : i + 4),
      );
    }
    return buffer.toString();
  }
}
