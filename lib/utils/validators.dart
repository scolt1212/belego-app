import 'iban.dart';
import 'money.dart';
import 'swiss_phone_number.dart';
import 'swiss_vat_number.dart';

/// Einfache, wiederverwendbare Feldvalidierungen für Formulare.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _swissPostalCodePattern = RegExp(r'^\d{4}$');

  static String? required(String? value, {String message = 'Pflichtfeld'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bitte E-Mail-Adresse eingeben';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Bitte eine gültige E-Mail-Adresse eingeben';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Bitte Passwort eingeben';
    if (value.length < 8) return 'Mindestens 8 Zeichen';
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) return 'Bitte Passwort bestätigen';
    if (value != originalPassword) return 'Passwörter stimmen nicht überein';
    return null;
  }

  static String? positiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pflichtfeld';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Bitte eine gültige Zahl eingeben';
    }
    return null;
  }

  /// Für Mengenangaben: positive Dezimalzahl (Komma oder Punkt erlaubt).
  static String? positiveDecimal(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pflichtfeld';
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return 'Bitte eine gültige Menge eingeben';
    }
    return null;
  }

  /// Für CHF-Beträge: nicht-negative Zahl mit höchstens 2 Nachkommastellen
  /// (Rundung erfolgt über [Money.parseChfToRappen]).
  static String? chfAmount(String? value) {
    if (Money.parseChfToRappen(value ?? '') == null) {
      return 'Bitte einen gültigen Betrag eingeben';
    }
    return null;
  }

  /// IBAN: Format- und echte Modulo-97-Prüfsummenprüfung (siehe [Iban]).
  static String? iban(String? value) => Iban.validate(value);

  /// Schweizer MWST-Nummer (UID), nur relevant wenn die Firma MWST-pflichtig
  /// ist (siehe [SwissVatNumber]).
  static String? vatNumber(String? value) => SwissVatNumber.validate(value);

  /// Schweizer PLZ: muss genau vier Ziffern enthalten. Bei anderen Ländern
  /// wird nur geprüft, dass ein Wert vorhanden ist.
  static String? postalCode(String? value, {required bool isSwitzerland}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Pflichtfeld';
    if (isSwitzerland && !_swissPostalCodePattern.hasMatch(trimmed)) {
      return 'Bitte eine gültige vierstellige Schweizer PLZ eingeben.';
    }
    return null;
  }

  /// Für Termine: Endzeit darf nicht vor der Startzeit liegen. Beide Werte
  /// als Minuten seit Mitternacht (bewusst kein `TimeOfDay`, damit diese
  /// Datei ohne Flutter-Abhängigkeit bleibt).
  static String? appointmentEndTime(int startMinutes, int endMinutes) {
    if (endMinutes < startMinutes) {
      return 'Die Endzeit darf nicht vor der Startzeit liegen.';
    }
    return null;
  }

  /// Telefonnummer: strenge Schweizer Formatprüfung bei Land „Schweiz“,
  /// sonst eine allgemeinere internationale Plausibilitätsprüfung.
  static String? phoneNumber(String? value, {required bool isSwitzerland}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Bitte Telefonnummer eingeben';
    if (isSwitzerland) {
      return SwissPhoneNumber.isValid(raw)
          ? null
          : SwissPhoneNumber.errorMessage;
    }
    return SwissPhoneNumber.isValidInternational(raw)
        ? null
        : SwissPhoneNumber.internationalErrorMessage;
  }
}
