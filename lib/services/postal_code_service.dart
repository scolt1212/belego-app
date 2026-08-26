// ignore_for_file: prefer_initializing_formals
// (Der öffentliche Konstruktor-Parametername "entries" bleibt bewusst anders
// als das private Feld "_entries", damit die Bezeichnung von aussen lesbar
// bleibt.)
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Ein Eintrag aus dem amtlichen Schweizer PLZ-/Ortschaftenverzeichnis.
class PostalCodeEntry {
  const PostalCodeEntry({
    required this.postalCode,
    required this.locality,
    this.canton = '',
  });

  final String postalCode;
  final String locality;
  final String canton;

  /// Anzeigeformat für Vorschläge, z.B. „8180 Bülach (ZH)“, oder ohne Kanton
  /// „8180 Bülach“, falls keiner bekannt ist.
  String get label => canton.isEmpty
      ? '$postalCode $locality'
      : '$postalCode $locality ($canton)';

  factory PostalCodeEntry.fromJson(Map<String, dynamic> json) =>
      PostalCodeEntry(
        postalCode: json['postalCode'] as String,
        locality: json['locality'] as String,
        canton: (json['canton'] as String?) ?? '',
      );
}

/// Sucht Schweizer Postleitzahlen und Ortschaften für die Autovervollständigung
/// bei Firmen- und Kundenadressen.
///
/// Datengrundlage: das amtliche Ortschaftenverzeichnis von swisstopo, siehe
/// `assets/data/README.md` für Quelle, Abrufdatum und Verarbeitung. Die Daten
/// werden einmalig als App-Asset geladen (`loadFromAsset`) und danach rein
/// lokal/offline durchsucht – es werden keine Adresseingaben an eine externe
/// API gesendet.
class PostalCodeService {
  const PostalCodeService({required List<PostalCodeEntry> entries})
    : _entries = entries;

  final List<PostalCodeEntry> _entries;

  static const String defaultAssetPath = 'assets/data/swiss_postal_codes.json';

  /// Lädt und parst das gebündelte PLZ-/Ortschaften-Asset. Wird einmalig beim
  /// App-Start aufgerufen (siehe `main.dart`).
  static Future<List<PostalCodeEntry>> loadEntriesFromAsset({
    String assetPath = defaultAssetPath,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map((e) => PostalCodeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static const Map<String, String> _diacriticsFoldMap = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  /// Vereinheitlicht Gross-/Kleinschreibung und häufige Akzente/Umlaute für
  /// einen tolerantere Ortssuche (z.B. "Bül"/"bül" findet "Bülach").
  static String _fold(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_diacriticsFoldMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Sucht anhand einer Teileingabe (PLZ-Anfang oder Ortsname).
  /// Reagiert bereits ab dem ersten Zeichen. Ist die Eingabe rein numerisch,
  /// wird nach PLZ-Anfang gesucht, sonst nach Ortsname (Gross-/Kleinschreibung
  /// und gängige Akzente werden ignoriert). Genaue Treffer erscheinen zuerst,
  /// danach aufsteigend nach PLZ bzw. alphabetisch nach Ort. Liefert
  /// höchstens [limit] Treffer.
  List<PostalCodeEntry> search(String query, {int limit = 10}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final isNumericQuery = _digitsOnly.hasMatch(trimmed);
    final foldedQuery = _fold(trimmed);

    final matches = _entries.where((entry) {
      if (isNumericQuery) return entry.postalCode.startsWith(trimmed);
      return _fold(entry.locality).contains(foldedQuery);
    }).toList();

    // Rang 0 = genaue Übereinstimmung, 1 = beginnt mit der Eingabe,
    // 2 = Eingabe kommt irgendwo vor. So verdrängen entferntere
    // Teiltreffer nicht die naheliegenden (z.B. "Hin" -> "Hinwil" statt
    // nur zufällig alphabetisch früherer "…hin…"-Orte).
    int rankOf(PostalCodeEntry entry) {
      if (isNumericQuery) {
        if (entry.postalCode == trimmed) return 0;
        return 1; // alles andere ist per Filter bereits ein Präfixtreffer.
      }
      final folded = _fold(entry.locality);
      if (folded == foldedQuery) return 0;
      if (folded.startsWith(foldedQuery)) return 1;
      return 2;
    }

    int compare(PostalCodeEntry a, PostalCodeEntry b) {
      final rankDiff = rankOf(a).compareTo(rankOf(b));
      if (rankDiff != 0) return rankDiff;
      if (isNumericQuery) return a.postalCode.compareTo(b.postalCode);
      return a.locality.toLowerCase().compareTo(b.locality.toLowerCase());
    }

    matches.sort(compare);
    return matches.take(limit).toList();
  }

  /// Prüft, ob eine PLZ/Ort-Kombination im amtlichen Verzeichnis existiert
  /// (Gross-/Kleinschreibung und Akzente werden ignoriert).
  bool isValidCombination(String postalCode, String locality) {
    final trimmedPostalCode = postalCode.trim();
    final foldedLocality = _fold(locality.trim());
    if (trimmedPostalCode.isEmpty || foldedLocality.isEmpty) return false;
    return _entries.any(
      (entry) =>
          entry.postalCode == trimmedPostalCode &&
          _fold(entry.locality) == foldedLocality,
    );
  }
}
