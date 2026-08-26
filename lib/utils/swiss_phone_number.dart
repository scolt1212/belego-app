/// Validierung und Normalisierung von Schweizer Telefonnummern.
///
/// Akzeptiert lokale Schreibweisen (führende „0“) sowie internationale
/// Schreibweisen mit „+41“ oder „0041“ und normalisiert gültige Nummern
/// einheitlich auf das Format „+41XXXXXXXXX“.
///
/// Es wird ausschliesslich das Format geprüft – nicht, ob die Nummer
/// tatsächlich vergeben oder erreichbar ist.
class SwissPhoneNumber {
  SwissPhoneNumber._();

  static const String errorMessage =
      'Bitte eine gültige Schweizer Telefonnummer eingeben, z. B. 076 756 75 68 oder +41 76 756 75 68.';

  static const String internationalErrorMessage =
      'Bitte eine gültige Telefonnummer eingeben.';

  static final RegExp _subscriberPattern = RegExp(r'^\d{9}$');
  static final RegExp _fantasyDigitsPattern = RegExp(r'^(\d)\1{8}$');

  /// Entfernt Leerzeichen, Bindestriche und Klammern; behält ein führendes
  /// „+“ und alle Ziffern.
  static String _stripFormatting(String raw) {
    final trimmed = raw.trim();
    final hasLeadingPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasLeadingPlus ? '+$digits' : digits;
  }

  static bool _isPlausibleSubscriberNumber(String subscriber) {
    if (!_subscriberPattern.hasMatch(subscriber)) return false;
    // Offensichtliche Fantasieziffern (z.B. neun gleiche Ziffern) ablehnen.
    if (_fantasyDigitsPattern.hasMatch(subscriber)) return false;
    return true;
  }

  /// Gibt die normalisierte Form (`+41XXXXXXXXX`) zurück, oder `null`, wenn
  /// die Eingabe keine gültige Schweizer Telefonnummer ist.
  static String? normalize(String raw) {
    var cleaned = _stripFormatting(raw);

    if (cleaned.startsWith('0041')) {
      cleaned = '+41${cleaned.substring(4)}';
    }

    if (cleaned.startsWith('+41')) {
      final subscriber = cleaned.substring(3);
      return _isPlausibleSubscriberNumber(subscriber) ? '+41$subscriber' : null;
    }

    if (cleaned.startsWith('0') && cleaned.length > 1) {
      final subscriber = cleaned.substring(1);
      return _isPlausibleSubscriberNumber(subscriber) ? '+41$subscriber' : null;
    }

    return null;
  }

  static bool isValid(String raw) => normalize(raw) != null;

  /// Formatiert eine normalisierte Nummer (`+41XXXXXXXXX`) gut lesbar,
  /// z.B. „+41 76 756 75 68“. Andere Eingaben werden unverändert
  /// zurückgegeben.
  static String formatForDisplay(String normalized) {
    if (!normalized.startsWith('+41') || normalized.length != 12) {
      return normalized;
    }
    final rest = normalized.substring(3);
    return '+41 ${rest.substring(0, 2)} ${rest.substring(2, 5)} ${rest.substring(5, 7)} ${rest.substring(7, 9)}';
  }

  /// Sehr allgemeine Plausibilitätsprüfung für Telefonnummern ausserhalb der
  /// Schweiz. Prüft nur eine plausible Länge, keine länderspezifischen
  /// Regeln. Eine echte internationale Validierung folgt später (siehe
  /// ROADMAP.md).
  static bool isValidInternational(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 15;
  }
}
