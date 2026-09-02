import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';

/// Speichert die echten (nicht Demo-) Kontakte dauerhaft lokal auf diesem
/// Gerät über `shared_preferences` – funktioniert ohne zusätzliche native
/// Einrichtung auf Android, iOS, Web und Desktop (auf Web z.B. via
/// `localStorage`). Es gibt noch kein Benutzerkonto/Backend (siehe
/// ROADMAP.md): die Kontakte sind deshalb lokal auf diesem Gerät
/// gespeichert, nicht kontoübergreifend synchronisiert. Demo-Kontakte werden
/// nie über dieses Repository gespeichert (siehe `RootShell`).
class ContactRepository {
  ContactRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'belego_contacts_v1';

  /// Lädt einmalig beim App-Start die zugrunde liegende Speicherinstanz.
  /// Alle folgenden Lese-/Schreibzugriffe sind danach synchron.
  static Future<ContactRepository> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ContactRepository._(prefs);
  }

  /// Liest die aktuell gespeicherten Kontakte. Liefert eine leere Liste,
  /// wenn noch nie gespeichert wurde oder die Daten nicht lesbar sind (z.B.
  /// nach einer beschädigten Installation) – erfindet nie Beispieldaten.
  List<Contact> readAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<Contact> contacts) async {
    final encoded = json.encode(contacts.map((c) => c.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
