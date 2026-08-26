import 'dart:typed_data';

/// Angaben aus der Firmeneinrichtung. Wird vorerst nur lokal im
/// Arbeitsspeicher gehalten, nicht dauerhaft gespeichert.
///
/// Die Adresse und die Bankangaben sind bewusst als einzelne Felder
/// modelliert, damit sie später direkt für Rechnungen, Offerten und
/// Schweizer QR-Rechnungen wiederverwendet werden können.
class CompanyProfile {
  String companyName = '';

  // Ansprechperson – vorbelegt aus der Registrierung, aber änderbar.
  String firstName = '';
  String lastName = '';

  // Strukturierte Firmenadresse.
  String street = '';
  String houseNumber = '';
  String postalCode = '';
  String city = '';
  String country = 'Schweiz';

  String phoneNumber = '';
  String businessEmail = '';

  // Normale IBAN. Belego soll daraus später eine Schweizer QR-Rechnung ohne
  // strukturierte QR-Referenz erstellen können. Eine separate QR-IBAN (für
  // QR-Rechnungen MIT Referenz) ist eine spätere Expertenfunktion, siehe
  // ROADMAP.md.
  String iban = '';

  bool isVatLiable = false;
  String vatNumber = '';

  /// Standard-MWST-Satz für neue Rechnungspositionen. Bleibt `0.0`, solange
  /// die Firma nicht MWST-pflichtig ist.
  double vatRate = 0.0;

  int paymentTermDays = 30;

  /// Firmenlogo, ausgewählt über die echte, plattformübergreifende
  /// Logoauswahl (Android/iOS-Galerie bzw. Web-Dateiauswahl). Wird vorerst
  /// nur im laufenden App-Zustand gehalten, siehe ROADMAP.md für dauerhafte
  /// Speicherung. Für die spätere Verwendung auf Rechnungen und Offerten
  /// (oben links) vorgesehen; ohne Logo erscheint dort der Firmenname.
  Uint8List? logoBytes;
  String? logoFileName;

  bool get hasLogo => logoBytes != null;
}
