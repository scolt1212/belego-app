/// Rechnungsempfänger. Noch keine echte Kontakt-Datenbank – die Angaben
/// werden pro Rechnung erfasst (siehe ROADMAP.md für spätere Kontaktauswahl).
class InvoiceCustomer {
  String companyOrName = '';
  String firstName = '';
  String lastName = '';
  String street = '';
  String houseNumber = '';
  String postalCode = '';
  String city = '';
  String country = 'Schweiz';
  String email = '';

  /// Mindestens Firma oder vollständiger Personenname muss vorhanden sein.
  bool get hasValidName =>
      companyOrName.trim().isNotEmpty ||
      (firstName.trim().isNotEmpty && lastName.trim().isNotEmpty);

  /// Für eine fertige Rechnung erforderliche Adressangaben sind vorhanden.
  bool get hasCompleteAddress =>
      street.trim().isNotEmpty &&
      houseNumber.trim().isNotEmpty &&
      postalCode.trim().isNotEmpty &&
      city.trim().isNotEmpty;

  String get displayName {
    if (companyOrName.trim().isNotEmpty) return companyOrName.trim();
    return '${firstName.trim()} ${lastName.trim()}'.trim();
  }
}
