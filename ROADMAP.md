# Belego – Roadmap

## Bereits erledigt

Alle Punkte in diesem Abschnitt funktionieren tatsächlich und sind durch
`flutter test` abgedeckt.

- Grundgerüst der App: Theme mit Sky-Blau-Akzent auf Weiss/Grau, einheitliche
  Eingabefeld-Gestaltung über `lib/theme/app_theme.dart`
  (`inputDecorationTheme`) – jedes Feld ist bereits ohne Fokus durch einen
  sichtbaren grauen Rahmen und einen sehr hellen blaugrauen Hintergrund
  als Eingabefeld erkennbar, bei Fokus deutlich sky-blau, bei Fehlern rot.
  Automatisch berechnete/vergebene Felder verwenden bewusst eine andere,
  graue „gesperrte“ Optik mit Schloss-Symbol. Einheitlich für Registrierung,
  Anmeldung, Firmeneinrichtung und Rechnungseditor, nicht pro Feld einzeln
  implementiert.
- Tab-Navigation mit 4 Tabs (Heute, Assistent, Dokumente, Kontakte) via
  `IndexedStack` + `BottomNavigationBar` (`lib/screens/root_shell.dart`).
- Startbildschirm, Demo-Modus mit „Demo verlassen“.
- Registrierung mit vollständiger Validierung (Pflichtfelder, E-Mail-Format,
  Passwort ≥ 8 Zeichen, übereinstimmende Passwortbestätigung,
  Anzeigen/Ausblenden-Symbol); Vorname/Nachname/E-Mail werden automatisch in
  die Firmeneinrichtung übernommen, dort über „Ändern“ korrigierbar, ohne
  erneute Pflichteingabe.
- Firmeneinrichtung in 3 Schritten (Unternehmen, Finanzen, Abschluss):
  - Strukturierte Adresse (Land, PLZ/Ort, Strasse, Hausnummer) in dieser
    Reihenfolge: zuerst Land wählen und PLZ/Ort suchen, danach erst
    Strasse und Hausnummer eintragen. Dieselbe Reihenfolge gilt auch für
    die Kundenadresse im Rechnungseditor
    (`lib/widgets/structured_address_fields.dart`).
  - **Vollständige amtliche Schweizer PLZ-/Ortschaftssuche** auf Basis des
    Ortschaftenverzeichnisses von swisstopo (`assets/data/README.md`),
    nicht mehr eine kleine Testliste. Suche ab dem ersten Zeichen, per
    PLZ-Präfix oder Ortsname, Gross-/Kleinschreibung und gängige Akzente
    werden ignoriert, Vorschläge im Format „8180 Bülach (ZH)“. Bei Land
    „Schweiz“ wird die PLZ/Ort-Kombination gegen das Verzeichnis geprüft.
  - Schweizer Telefonnummernvalidierung und -normalisierung
    (`lib/utils/swiss_phone_number.dart`).
  - **Ein Pflichtfeld `IBAN`** mit echter Modulo-97-Prüfsummenprüfung
    (`lib/utils/iban.dart`) – kein separates QR-IBAN-Feld mehr.
  - MWST-Bereich: bei „Nein“ Standardsatz fix `0.0 %`; bei „Ja“ Pflichtfeld
    MWST-Nummer (Format `CHE-123.456.789 MWST`) und wählbarer
    Standard-MWST-Satz (8.1 / 3.8 / 2.6 / 0.0 %).
  - Gut lesbare, responsive Abschluss-Zusammenfassung (Firmenname,
    Ansprechperson, Adresse, Telefon, E-Mail, IBAN, MWST-Status/-Nummer/
    -Satz, Zahlungsfrist, Logo-Status), ohne QR-IBAN. Lange Werte brechen
    auf schmalen Bildschirmen um (Label über Wert statt nebeneinander),
    auf breiteren Bildschirmen bleibt die zweispaltige Darstellung.
  - **Echte, plattformübergreifende Firmenlogo-Auswahl** (Android/iOS-
    Galerie, Web-Dateiauswahl) über das offizielle `image_picker`-Paket:
    PNG/JPG/JPEG bis 5 MB, Vorschau (max. 160×80, `BoxFit.contain`,
    transparente PNGs werden unterstützt), Ersetzen und Entfernen möglich.
    Ungültiges Format, zu grosse oder beschädigte Dateien werden mit
    verständlicher Meldung abgelehnt. Das Logo wird nur für die laufende
    App-Sitzung im `CompanyProfile` gehalten (siehe „Später geplant“ für
    dauerhafte Speicherung).
- Leerer Zustand auf „Heute“ für neu registrierte Benutzer, ohne fremde
  Beispieldaten.
- Rechnungseditor (`lib/screens/documents/invoice/`):
  - Kunde mit denselben strukturierten Adressfeldern und derselben
    amtlichen PLZ-/Ortssuche wie die Firmeneinrichtung.
  - Rechnungsangaben mit automatisch vergebener Rechnungsnummer
    (`RE-2026-0001`, …) und automatisch berechnetem Fälligkeitsdatum;
    beide optisch klar als automatisch gekennzeichnet (grauer Hintergrund,
    Schloss-Symbol, „Automatisch vergeben“/„Automatisch berechnet“) und
    nicht editierbar.
  - Die Rechnungsnummer wird erst beim ersten erfolgreichen Speichern fest
    vergeben (ein geöffnetes und wieder verworfenes leeres Formular
    verbraucht keine Nummer); beim Bearbeiten bleibt sie unverändert.
  - Beliebig viele Positionen (Menge/Einheit/Einzelpreis/MWST-Satz je
    Position, Standardsatz aus der Firma vorbelegt), Berechnung in Rappen
    ohne Gleitkomma-Anzeigefehler, korrekte Zusammenfassung auch bei
    unterschiedlichen MWST-Sätzen pro Position.
  - Validierung vor „Vorschau“ und „Als Entwurf speichern“: unvollständige
    oder ungültige Angaben werden nicht stillschweigend gespeichert,
    Fehler werden angezeigt und zum Formularanfang gescrollt.
  - Bildschirm-Vorschau und „Als Entwurf speichern“ mit Verwerfungsdialog
    bei ungespeicherten Änderungen; ohne Änderungen kann der Editor direkt
    verlassen werden.
- Dokumententwürfe: gespeicherte Rechnungsentwürfe erscheinen im Tab
  „Dokumente“, klar als „Entwurf“ gekennzeichnet, mit Rechnungsnummer,
  Empfänger, Datum und Betrag; können erneut geöffnet und bearbeitet werden,
  ohne dabei dupliziert zu werden. Zählen nicht als offene Forderung auf
  „Heute“. Demo-Beispieldaten erscheinen ausschliesslich im Demo-Modus.
- Begrenzte, zentrierte Inhaltsbreite auf grossen Bildschirmen, Formulare
  bleiben auf Smartphones gut bedienbar.

## Aktuell in Arbeit

- Nichts – dieser Checkpoint schliesst Registrierung, Firmeneinrichtung,
  Schweizer Adresssuche, Validierung und Rechnungserstellung als
  produktionsnahe erste Version ab.

## Später geplant

- Echte Authentifizierung und Backend-Anbindung (Login/Registrierung sind
  aktuell nur lokal klickbare Abläufe, kein echtes Benutzerkonto).
- Dauerhafte lokale Speicherung bzw. Backend für Firmeneinrichtung,
  Rechnungsentwürfe und das Firmenlogo (aktuell nur lokaler App-Zustand,
  geht bei einem vollständigen Neustart der App verloren – für dauerhafte
  Speicherung würde das Logo z.B. zusätzlich als Datei im
  Anwendungsverzeichnis abgelegt und der Pfad persistiert werden müssen).
- Aktualisierung der Schweizer PLZ-/Ortschaftsdaten bei neuen Ausgaben des
  swisstopo-Ortschaftenverzeichnisses (Bezugsweg in
  `assets/data/README.md` dokumentiert).
- Allgemeine internationale Telefonnummernvalidierung für Adressen
  ausserhalb der Schweiz (aktuell nur eine grobe
  Plausibilitätsprüfung nach Ziffernanzahl).
- Professionelle A4-PDF-Erstellung für Rechnungen und Offerten:
  Firmenlogo oben links (Firmenname als Ersatz, falls kein Logo vorhanden
  ist), Rechnungspositionen mit Menge/Einheit/Einzelpreis/MWST,
  Zwischensumme/MWST/Gesamtbetrag in CHF, neutrale Standardschrift und
  korrekt strukturierte Adressen (siehe `CLAUDE.md`, Abschnitt
  „Rechnungen & Offerten“).
- Schweizer QR-Zahlteil nach dem offiziellen Swiss-QR-Rechnungsstandard.
  Wichtig für die spätere Umsetzung: **nicht jede normale IBAN ist ohne
  Weiteres für jede Referenzart geeignet.** Zwei Modelle sind zu
  unterscheiden und korrekt zu validieren:
  - normale IBAN mit **SCOR-Referenz** (strukturierte Referenz nach
    ISO 11649, z.B. `RF18...`) oder ganz ohne Referenz, oder
  - **QR-IBAN** (spezieller IID-Bereich) mit **QR-Referenz** (26-stellig,
    Modulo-10-Prüfziffer).
  Welches Modell verwendet wird, hängt von der Art der IBAN und der
  gewählten Referenz ab und muss vor der PDF-Erstellung geprüft werden.
  Eine optionale QR-IBAN mit QR-Referenz bleibt dafür eine spätere
  Expertenfunktion – bewusst nicht Teil der aktuellen Firmeneinrichtung,
  die nur ein einfaches `IBAN`-Feld hat.
- E-Mail-Versand von Rechnungen/Offerten.
- Dauerhafte, pro Firma eindeutige Rechnungsnummernvergabe (aktuell nur
  lokal je App-Sitzung nachvollziehbar aus Jahr + laufender Nummer).
- Auswahl bereits gespeicherter Kontakte als Rechnungsempfänger, sobald der
  „Kontakte“-Tab eine echte Kontakt-Datenbank hat (aktuell wird der Kunde
  pro Rechnung neu erfasst).
- Kalenderfunktion / Terminübersicht.
- Inhalt für den „Assistent“-Tab (Konzept noch offen, kein KI-Assistent in
  dieser Version).
- Inhalt für den „Kontakte“-Tab (Kunden/Lieferanten verwalten).
- „Offerte erstellen“ als echte Funktion (aktuell ein ehrlicher
  Platzhalter-Button: „Diese Funktion folgt in einem späteren Schritt.“).
- Bezahlstatus für Rechnungen (bezahlt/überfällig/gemahnt).
- Weitere Karten auf dem „Heute“-Screen (z.B. offene Aufgaben, letzte
  Aktivitäten) – nach Bedarf.
