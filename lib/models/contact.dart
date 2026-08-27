import '../utils/id_generator.dart';

/// Ein einfacher Kontakt, der z.B. mit einem Termin verknüpft werden kann.
/// Es gibt noch keine echte Kontaktverwaltung (kein „Kontakt hinzufügen“ im
/// UI, kein eigener Tab-Inhalt für „Kontakte“) – dieses Modell und die dazu
/// gehörende In-Memory-Liste in `RootShell` bilden die Datengrundlage für die
/// optionale Kontaktsuche im Termin-Dialog. Siehe ROADMAP.md für die spätere
/// vollständige Kontaktverwaltung.
class Contact {
  Contact({
    String? id,
    required this.displayName,
    this.phone = '',
    this.email = '',
    this.address = '',
  }) : id = id ?? IdGenerator.next('kontakt');

  final String id;
  String displayName;
  String phone;
  String email;
  String address;
}
