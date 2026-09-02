import '../utils/id_generator.dart';

/// Ein Kontakt (Kunde, Lieferant, oder beides). Kann optional mit Terminen
/// (`Appointment.contactId`) und mit Rechnungen (`InvoiceCustomer.contactId`)
/// verknüpft werden – jeweils nur über die stabile [id], nie über den Namen.
///
/// [isCustomer] und [isSupplier] sind bewusst zwei unabhängige Merkmale statt
/// einer einzelnen Kategorie: ein Kontakt kann Kunde, Lieferant oder beides
/// gleichzeitig sein (siehe CLAUDE.md/ROADMAP.md).
///
/// Ein Kontakt wird nie hart gelöscht, wenn er bereits von einer Rechnung
/// oder einem Termin verwendet wird – stattdessen wird er archiviert
/// ([isArchived]), damit historische Dokumente ihre Daten behalten. Ein
/// archivierter Kontakt bleibt für bestehende Verknüpfungen sichtbar,
/// erscheint aber nicht mehr in Auswahllisten für neue Dokumente/Termine.
class Contact {
  Contact({
    String? id,
    this.isCompany = true,
    this.companyName = '',
    this.salutation = '',
    this.firstName = '',
    this.lastName = '',
    this.street = '',
    this.houseNumber = '',
    this.postalCode = '',
    this.city = '',
    this.country = 'Schweiz',
    this.email = '',
    this.phone = '',
    this.iban = '',
    this.note = '',
    this.isCustomer = true,
    this.isSupplier = false,
    this.isArchived = false,
  }) : id = id ?? IdGenerator.next('kontakt');

  final String id;

  /// Firma oder Privatperson – bestimmt, ob [companyName] oder
  /// [firstName]/[lastName] massgeblich sind.
  bool isCompany;
  String companyName;

  /// Anrede, rein optional (z.B. „Herr“/„Frau“), nur für Privatpersonen
  /// relevant.
  String salutation;

  /// Bei einer Privatperson der vollständige Name; bei einer Firma optional
  /// die Ansprechperson (z.B. „Herr Müller“ bei „Muster AG“) – dasselbe Feld
  /// dient bewusst beiden Zwecken, damit kein zusätzliches Modellfeld nötig
  /// ist. Für [displayName] bei einer Firma ohne Bedeutung.
  String firstName;
  String lastName;

  String street;
  String houseNumber;
  String postalCode;
  String city;
  String country;

  String email;
  String phone;

  /// Normale IBAN, optional (z.B. für Gutschriften an Lieferanten). Gespeichert
  /// ohne Leerzeichen, siehe [Iban.normalize].
  String iban;

  String note;

  bool isCustomer;
  bool isSupplier;

  /// Archivierte Kontakte bleiben für bestehende Verknüpfungen (Rechnungen,
  /// Termine) sichtbar, erscheinen aber nicht mehr in Auswahllisten für neue
  /// Dokumente – siehe Klassendokumentation.
  bool isArchived;

  /// Firma bzw. vollständiger Personenname – wie bei [InvoiceCustomer].
  String get displayName {
    if (isCompany) return companyName.trim();
    return '${firstName.trim()} ${lastName.trim()}'.trim();
  }

  /// Vorname + Nachname, unabhängig von [isCompany] – bei einer Firma die
  /// optionale Ansprechperson, sonst identisch mit [displayName]. Leer, wenn
  /// keine Angabe vorhanden ist.
  String get contactPersonName =>
      '${firstName.trim()} ${lastName.trim()}'.trim();

  /// Zusammengesetzte Adresse für kompakte Anzeigen (z.B. Kontaktsuche im
  /// Termin-Dialog), aus den strukturierten Feldern gebildet.
  String get address {
    final parts = <String>[];
    final streetLine = [
      street.trim(),
      houseNumber.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    if (streetLine.isNotEmpty) parts.add(streetLine);
    final cityLine = [
      postalCode.trim(),
      city.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    if (cityLine.isNotEmpty) parts.add(cityLine);
    return parts.join(', ');
  }

  /// Mindestens Firma oder vollständiger Personenname muss vorhanden sein –
  /// dieselbe Regel wie bei [InvoiceCustomer.hasValidName].
  bool get hasValidName => isCompany
      ? companyName.trim().isNotEmpty
      : (firstName.trim().isNotEmpty || lastName.trim().isNotEmpty);

  /// Für einen rechnungsfähigen Kunden erforderliche Adressangaben sind
  /// vorhanden.
  bool get hasCompleteAddress =>
      street.trim().isNotEmpty &&
      houseNumber.trim().isNotEmpty &&
      postalCode.trim().isNotEmpty &&
      city.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'isCompany': isCompany,
    'companyName': companyName,
    'salutation': salutation,
    'firstName': firstName,
    'lastName': lastName,
    'street': street,
    'houseNumber': houseNumber,
    'postalCode': postalCode,
    'city': city,
    'country': country,
    'email': email,
    'phone': phone,
    'iban': iban,
    'note': note,
    'isCustomer': isCustomer,
    'isSupplier': isSupplier,
    'isArchived': isArchived,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String?,
    isCompany: json['isCompany'] as bool? ?? true,
    companyName: json['companyName'] as String? ?? '',
    salutation: json['salutation'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    street: json['street'] as String? ?? '',
    houseNumber: json['houseNumber'] as String? ?? '',
    postalCode: json['postalCode'] as String? ?? '',
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? 'Schweiz',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    iban: json['iban'] as String? ?? '',
    note: json['note'] as String? ?? '',
    isCustomer: json['isCustomer'] as bool? ?? true,
    isSupplier: json['isSupplier'] as bool? ?? false,
    isArchived: json['isArchived'] as bool? ?? false,
  );
}
