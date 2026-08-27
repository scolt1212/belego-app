# Belego – Technik- und Designregeln

Verbindliche Grundregeln für dieses Projekt. Bei Unsicherheit gelten diese
Regeln, bis der Nutzer sie ausdrücklich ändert.

## Technik

- **Framework:** Flutter, Zielplattformen Android, iOS und Web.
- **State-Management:** vorläufig einfaches `setState` / `StatefulWidget`.
  Kein Provider, Riverpod, Bloc o.ä., solange nicht ausdrücklich gewünscht.
- **Navigation:** `IndexedStack` + `NavigationBar` (Material 3, offizielles
  Flutter-Bordmittel, kein Zusatzpaket), kein Routing-Paket (kein
  `go_router`) ohne ausdrücklichen Auftrag.
- **Abhängigkeiten:** so wenig Zusatzpakete wie möglich. Neue Pakete nur
  hinzufügen, wenn es ohne sie unverhältnismässig aufwändig würde – und dann
  kurz begründen.

## Design

- **Akzentfarbe:** ausschliesslich ein kräftiges Belego-Blau
  (`AppColors.sky500`/`sky600`, `#0878F9`) als Haupt- und Aktionsfarbe. Kein
  weiterer Akzent- oder Markenfarbton.
- **Hintergrund/Flächen:** modernes Weiss/Hellblau als Grundlage – sehr
  helles Hintergrundblau (`AppColors.background`/`sky50`, `#F6FAFF`), weisse
  Karten (`AppColors.surface`) mit feinem, klar sichtbarem hellblauen Rahmen
  (`AppColors.border`, `#DCE6F2`), siehe `lib/theme/app_theme.dart`,
  `AppColors`. Grosse weiche, organische hellblaue Flächen im Hintergrund
  (`lib/screens/today/widgets/hero_background.dart`) sind auf der
  „Heute“-Seite ausdrücklich erwünscht, bleiben aber rein dekorativ
  (`IgnorePointer`) und fix während des Scrollens. Dunkles Navy
  (`AppColors.textPrimary`, `#071B49`) statt reinem Schwarz als Haupttext.
  Keine weiteren Buntfarben ausser für semantische Zustände: Orange
  (`AppColors.privateOrange`, `#F59E0B`) für private Termine/Aufgaben, Grün
  (`AppColors.paidGreen`, `#20B66A`) ausschliesslich für Bezahlt/Erledigt
  (nie für „Privat“), zurückhaltendes Rot (`AppColors.danger`) für Fehler
  und überfällige Rechnungen, neutrales Grau (`AppColors.draftGrey`) für
  Entwurf/keine Kategorie.
- **Ausnahme Rechnungs-Vorschau/PDF:** Das Farbsystem der App-Oberfläche
  gilt ausdrücklich NICHT für den eigentlichen Rechnungsinhalt.
  `InvoicePreviewScreen` (späteres PDF) bleibt bewusst neutral in
  Schwarz/Weiss/Grau.
- **Struktur:** vier Tabs unten – Heute, Assistent, Dokumente, Kontakte, als
  schwebende weisse Karte mit abgerundeten Ecken und Schatten
  (`lib/screens/root_shell.dart`) statt einer flächigen Leiste. Neue
  Hauptfunktionen werden diesen vier Tabs zugeordnet, nicht als
  zusätzlicher fünfter Tab.
- **Eingabefelder:** einheitlich über das zentrale `inputDecorationTheme` in
  `lib/theme/app_theme.dart` gestaltet, nicht pro Feld einzeln. Jedes Feld
  hat immer eine erkennbare hellblaue Umrandung (`AppColors.fieldBorder`)
  und einen leicht abgesetzten hellblauen Hintergrund (`AppColors.fieldFill`),
  bei Fokus deutlich sky-blau, bei Fehlern rot. Automatisch berechnete/
  vergebene Felder (z.B. Rechnungsnummer, Fälligkeitsdatum) verwenden
  stattdessen die abweichende, neutral graue `_AutoField`-Optik
  (`AppColors.autoFieldFill`) mit Schloss-Symbol, damit sie nicht wie
  kaputte oder normale Eingabefelder wirken.
- **Rechnungsstatus:** `InvoiceDraft.status` (`draft`/`open`/`paid`) ist der
  einzige gespeicherte Status. „Überfällig“ ist bewusst kein eigener Status,
  sondern wird aus `status == open` und dem Fälligkeitsdatum abgeleitet
  (`InvoiceDraft.isOverdue`), damit nie ein Widerspruch wie „überfällig und
  bezahlt“ entstehen kann. Zahlungen werden ausschliesslich manuell über
  „Als bezahlt markieren“ erfasst – niemals automatisch erkannt oder
  erfunden (keine Bankanbindung).

## Sprache & Format

- **Kommunikation:** Mit dem Nutzer wird auf Deutsch kommuniziert, ebenso
  Zusammenfassungen und Statusmeldungen im Chat.
- **App-Texte:** Alle sichtbaren Texte der App werden in klarem,
  professionellem Hochdeutsch für Schweizer Kunden verfasst. Kein Dialekt.
- **Schweizer Standardbegriffe:** z.B. „Offerte“ (nicht „Angebot“), „MWST“
  (nicht „USt.“/„MwSt.“), „CHF“ als Währung.
- **Schreibweise:** Schweizer Hochdeutsch (kein „ß“, stattdessen „ss“).
- **Code bleibt Englisch:** Programmcode, Dateinamen, Klassen, Funktionen und
  Variablen werden auf Englisch verfasst und folgen üblichen
  Flutter-/Dart-Konventionen. Technische Schlüsselwörter, Befehle und
  Fehlermeldungen (z.B. aus `flutter analyze`/`flutter test`) werden nicht
  übersetzt.
- **Währung:** ausschliesslich CHF, Schweizer Zahlenformat (Apostroph als
  Tausendertrennzeichen, z.B. `CHF 1'240.00`).
  In Code: `NumberFormat.currency(locale: 'de_CH', symbol: 'CHF')`.
- **Datum:** Schweizer Format (`dd.MM.yyyy`).
- **Telefonnummern:** Schweizer Nummern werden über
  `lib/utils/swiss_phone_number.dart` einheitlich auf `+41XXXXXXXXX`
  normalisiert gespeichert; angezeigt wird ein gut lesbares Format
  (`+41 76 298 12 12`). Akzeptiert werden lokale (`0…`) sowie internationale
  (`+41…`/`0041…`) Schreibweisen. Bei anderen Ländern gilt vorerst nur eine
  allgemeine Plausibilitätsprüfung (siehe `ROADMAP.md`).
- **IBAN:** ausschliesslich ein Pflichtfeld `IBAN` (kein separates
  QR-IBAN-Feld in der Firmeneinrichtung). Geprüft wird nicht nur Länge/
  Länderkürzel, sondern die echte Modulo-97-Prüfsumme nach ISO 7064
  (`lib/utils/iban.dart`). Anzeige in 4er-Gruppen, Eingabe wird intern
  gross geschrieben und von Leerzeichen bereinigt.
- **MWST:** Ist eine Firma nicht MWST-pflichtig, ist der Standardsatz immer
  `0.0 %` (kein anderer Wert wird gespeichert oder für neue
  Rechnungspositionen verwendet). Ist sie MWST-pflichtig, ist die
  MWST-Nummer Pflicht und wird im Schema `CHE-123.456.789 MWST` dargestellt
  (`lib/utils/swiss_vat_number.dart`, nur Formatprüfung, keine echte
  UID-Registerabfrage).
- **PLZ-/Ortssuche:** basiert auf dem amtlichen Ortschaftenverzeichnis von
  swisstopo (`assets/data/swiss_postal_codes.json`, siehe
  `assets/data/README.md` für Quelle/Abrufdatum), nicht auf einer manuell
  geschriebenen Testliste. Wird einmalig beim App-Start geladen
  (`PostalCodeService.loadEntriesFromAsset`) und danach rein lokal/offline
  durchsucht – keine Adresseingaben werden an eine externe API gesendet.
  PLZ und Ort werden bei Land „Schweiz“ als zusammengehörige Kombination
  geprüft, nicht nur einzeln.

## Rechnungen & Offerten (spätere Umsetzung, noch nicht implementiert)

Der Rechnungseditor mit Bildschirm-Vorschau ist bereits implementiert (siehe
`lib/screens/documents/invoice/`). Rechnungen und Offerten sollen zusätzlich
später als professionelle A4-PDFs erstellt werden. Festgehalten für die
spätere Umsetzung:

- Firmenlogo des Nutzers oben links; falls kein Logo vorhanden ist, erscheint
  stattdessen der Firmenname.
- Absender und Empfänger, korrekt strukturierte Adressen (siehe
  `CompanyProfile`).
- Rechnungs- bzw. Offertennummer, Datum und Zahlungsfrist.
- Leistungspositionen mit Menge, Einheit, Einzelpreis und MWST.
- Zwischensumme, MWST und Gesamtbetrag in CHF.
- Schweizer QR-Zahlteil am Ende der Rechnung, zunächst auf Basis der
  normalen IBAN ohne strukturierte QR-Referenz. Eine separate QR-IBAN mit
  QR-Referenz ist eine spätere Expertenfunktion (siehe `ROADMAP.md`), nicht
  Teil der aktuellen Firmeneinrichtung.
- Kein Belego-Logo auf Kundendokumenten – höchstens später ein sehr
  dezenter, freiwilliger Hinweis.

## Sonstiges

- Rückfragen stellen, bevor bei mehrdeutigen Anforderungen grössere
  Architektur- oder Design-Entscheidungen getroffen werden.
- Siehe `ROADMAP.md` für erledigte, laufende und geplante Funktionen.
