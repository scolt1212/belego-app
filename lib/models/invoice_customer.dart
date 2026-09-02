/// Rechnungsempfänger. Die Angaben werden pro Rechnung als eigenständige
/// Kopie erfasst – optional vorausgefüllt durch Auswahl eines gespeicherten
/// [Contact] (siehe `lib/screens/contacts/`), aber danach unabhängig davon.
class InvoiceCustomer {
  /// Stabile ID des Kontakts, aus dem diese Angaben ursprünglich übernommen
  /// wurden – rein informativ (z.B. um zu prüfen, ob ein Kontakt noch
  /// verwendet wird). Ändert NICHTS an bereits gestellten Rechnungen, wenn
  /// der verknüpfte Kontakt später bearbeitet wird: die Felder unten bleiben
  /// die massgebliche, unabhängige Kopie zum Zeitpunkt der Auswahl.
  String? contactId;

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
