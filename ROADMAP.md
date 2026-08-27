# Belego – Roadmap

## Bereits erledigt

Alle Punkte in diesem Abschnitt funktionieren tatsächlich und sind durch
`flutter test` abgedeckt.

- Grundgerüst der App: modernes Weiss/Hellblau-Farbsystem mit kräftigem
  Belego-Blau als durchgehender Aktionsfarbe (`lib/theme/app_theme.dart`,
  `AppColors`) – sehr helles Hintergrundblau (`background`/`sky50`), weisse
  Karten mit feinem, klar sichtbarem hellblauen Rahmen (`surface`/`border`),
  dunkles Navy als Haupttextfarbe (`textPrimary`). Orange für private
  Termine/Aufgaben (`privateOrange`), Grün ausschliesslich für Bezahlt/
  Erledigt (`paidGreen`), zurückhaltendes Rot für Fehler/überfällige
  Rechnungen (`danger`), neutrales Grau für Entwurf/keine Kategorie
  (`draftGrey`). Die Rechnungs-Vorschau (`InvoicePreviewScreen`, späteres
  PDF) bleibt bewusst neutral in Schwarz/Weiss/Grau und übernimmt dieses
  Farbsystem nicht. Einheitliche Eingabefeld-Gestaltung über
  `inputDecorationTheme` – jedes Feld ist bereits ohne Fokus durch einen
  sichtbaren hellblauen Rahmen und einen leicht abgesetzten hellblauen
  Hintergrund als Eingabefeld erkennbar, bei Fokus deutlich sky-blau, bei
  Fehlern rot. Automatisch berechnete/vergebene Felder verwenden bewusst
  eine andere, neutral graue „gesperrte“ Optik mit Schloss-Symbol.
  Einheitlich für Registrierung, Anmeldung, Firmeneinrichtung,
  Rechnungseditor sowie den Termin- und Aufgaben-Dialog, nicht pro Feld
  einzeln implementiert.
- Tab-Navigation mit 4 Tabs (Heute, Assistent, Dokumente, Kontakte) via
  `IndexedStack` + Material-3-`NavigationBar`, als schwebende weisse Karte
  mit abgerundeten Ecken und Schatten über dem Bildschirmrand dargestellt
  (`lib/screens/root_shell.dart`): aktiver Tab mit sky-blauem Symbol und
  heller Markierungsfläche, inaktive Tabs gut lesbar grau, per `SafeArea`
  vor Überlappung mit dem unteren Rand geschützt.
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
- **Startseite „Heute“ im überarbeiteten, kartenbasierten Design**
  (`lib/screens/today/today_screen.dart` + `lib/screens/today/widgets/`):
  - Fester Seitenaufbau: Kopfbereich (Menü, Belego-Markenlogo,
    Benachrichtigungen – `belego_top_bar.dart`), „Heute“-Überschrift,
    Begrüssung, Finanzübersicht, Umsatzdiagramm, Schnellaktionen, Kalender,
    Aufgaben, darüber grosse weiche hellblaue Hintergrundflächen
    (`hero_background.dart`), die beim Scrollen fix bleiben. Jeder Bereich
    erscheint genau einmal (testabgedeckt).
  - Begrüssung mit zeitabhängigem Gruss („Guten Morgen“/„Guten Tag“/„Guten
    Abend“) plus Vorname der Ansprechperson (falls vorhanden, blau
    hervorgehoben) und dem aktuellen Datum in Schweizer Langform.
  - Firmenlogo aus der Firmeneinrichtung wird direkt übernommen
    (`CompanyProfile.logoBytes`, dieselben Daten wie in der
    Rechnungsvorschau), proportional dargestellt
    (`lib/widgets/company_logo_avatar.dart`). Ohne Logo erscheint ein
    ruhiger Platzhalter mit den Firmen-Initialen bzw. einem neutralen
    Symbol – nie ein defektes Bild.
  - Echte Finanzübersicht mit drei Karten (Umsatz, offene Rechnungen,
    überfällige Rechnungen), berechnet aus den tatsächlichen
    Rechnungsstatus (`InvoiceDraft.status`: `draft`/`open`/`paid`,
    `InvoiceDraft.isOverdue`). Ein Zeitraum-Filter („Diesen Monat“/„Dieses
    Jahr“/„Gesamt“, `FinancePeriod`) ist echt funktional und beeinflusst
    ausschliesslich die Umsatzkennzahl; offene/überfällige Rechnungen sind
    immer der aktuelle Stand. Genaue Berechnungsregel siehe Kommentar in
    `_TodayScreenState._computeFinance`: Entwürfe zählen nirgends mit, der
    Umsatz ist die Summe der bezahlten Rechnungen mit Zahlungsdatum
    (`paidAt`) im gewählten Zeitraum. Die prozentuale Veränderung zum
    Vormonat wird nur bei „Diesen Monat“ und nur dann angezeigt, wenn der
    Vormonat selbst einen Umsatz > 0 hatte (`_computeRevenueChangePercent`)
    – ohne sinnvolle Vergleichsbasis erscheint ein neutraler Hinweis statt
    einer erfundenen Zahl. Die Karte „Überfällige Rechnungen“ zeigt bei
    null überfälligen Rechnungen bewusst eine positive Meldung („Alles im
    grünen Bereich“) statt einer leeren Verneinung. Werte zählen sofort
    nach jedem Statuswechsel neu (Count-up-Animation, ~700 ms, respektiert
    `MediaQuery.disableAnimations`). Klick auf „Offene“/„Überfällige
    Rechnungen“ öffnet den Dokumente-Tab mit passendem Filter
    (`DocumentsFilter` in `lib/screens/documents/documents_screen.dart`).
  - Animiertes Linien-/Flächendiagramm „Umsatz je Monat“
    (`lib/screens/today/widgets/revenue_chart.dart`, eigener `CustomPainter`,
    kein Chart-Paket) mit gestrichelten Gitterlinien, hervorgehobenem
    letzten Datenpunkt und CHF-Wertblase, ausschliesslich aus bezahlten
    Rechnungen für die letzten 6 Monate; baut sich beim ersten Anzeigen
    sichtbar von links nach rechts auf (~800 ms, respektiert
    `MediaQuery.disableAnimations`); ohne Umsatz erscheint eine ehrliche
    leere Darstellung.
  - Schnellaktionen mit genau vier Kacheln (kein Duplikat zum
    Kalender-Bereich): „Rechnung erstellen“ öffnet den bestehenden
    Rechnungseditor; „Offerte erstellen“, „Vertrag erstellen“ und „Kontakt
    hinzufügen“ sind sichtbar als „Bald verfügbar“ markiert und bewusst
    nicht antippbar, da diese Funktionen noch nicht existieren. „Vertrag
    erstellen“ ist als spätere allgemeine Vertragsfunktion vorgesehen
    (nicht nur Arbeitsverträge) – aktuell ausschliesslich als Kachel
    vorbereitet, ohne jede Vertragslogik dahinter.
    „Termin hinzufügen“ erscheint bewusst nur noch im Kalender-Bereich
    (kein doppelter Button mehr).
  - **Kalender mit Wochen- und Monatsansicht**
    (`lib/screens/today/widgets/week_calendar_card.dart`): Umschalter
    Woche/Monat, Blättern zu beliebigen vorherigen/folgenden Wochen bzw.
    Monaten, direkte Monat-/Jahresauswahl über den nativen Datumswähler
    (Antippen der Bereichsbeschriftung). Termine können für beliebige
    vergangene und zukünftige Tage angelegt werden, Wochenenden sind
    vollständig nutzbar. Markierung des heutigen Tages (immer sky-blau,
    unabhängig von Terminkategorien) und Punkt-Indikatoren bei vorhandenen
    Terminen – ein blauer Punkt für Geschäftlich, ein oranger für Privat,
    beide gleichzeitig bei gemischten Tagen; dieselbe Kategorie-Farbe wird
    auch in der Terminliste verwendet (Grün ist ausschliesslich für
    Bezahlt/Erledigt reserviert). Neues Terminmodell
    (`lib/models/appointment.dart`) mit Titel, Datum, Start-/Endzeit,
    optionaler Notiz, Kategorie (Geschäftlich = Blau, Privat = Orange)
    und optionaler Verknüpfung zu einem `Contact` (`contactId`). Termine
    können hinzugefügt, bearbeitet und gelöscht werden
    (`lib/screens/today/widgets/appointment_editor_dialog.dart`), mit
    Validierung (Titel/Datum/Startzeit Pflicht, Endzeit nicht vor
    Startzeit), separatem Beispieltext im Titelfeld, einer deutlichen
    Warnung beim Neuanlegen eines Termins in der Vergangenheit (bestehende
    vergangene Termine können weiterhin ohne Warnung angesehen/bearbeitet
    werden) sowie einer optionalen Kontaktsuche: durchsucht die bekannten
    Kontakte (`lib/models/contact.dart`) während der Eingabe, ein Treffer
    zeigt Firma/Name plus Telefon/E-Mail/Adresse und wird per Antippen mit
    dem Termin verknüpft, ohne den Titel zu verändern; ohne gespeicherte
    Kontakte erscheint der ehrliche Hinweis „Noch keine Kontakte
    gespeichert. Der Termin kann trotzdem erstellt werden.“ Es gibt noch
    keine echte Kontaktverwaltung (kein „Kontakt hinzufügen“ im UI) – die
    Kontaktliste bleibt für echte Konten deshalb leer, siehe „Später
    geplant“.
  - Kompakter Aufgabenbereich (`lib/screens/today/widgets/tasks_section.dart`)
    mit Aufgabenmodell (`lib/models/task_item.dart`): hinzufügen,
    erledigen/wieder öffnen, löschen, optionales Fälligkeitsdatum und
    optionale Kategorie (Geschäftlich = Blau, Privat = Orange, keine
    Kategorie = Grau), jeweils als farbiger Balken links an der
    Aufgabenzeile sichtbar – nicht nur im Dialog.
  - Dezente Animationen (Einblenden/Hochgleiten beim ersten Öffnen,
    Druckanimation auf Karten/Kacheln über `lib/widgets/pressable.dart`,
    sanfter Wechsel des ausgewählten Kalendertages, Count-up der
    Finanzwerte, aufbauendes Umsatzdiagramm, kurze Ein-/Ausblend-Animation
    beim Abhaken einer Aufgabe), respektieren
    `MediaQuery.disableAnimations`.
  - Responsive: einspaltig auf Smartphones, zweispaltig (Kalender/Aufgaben
    nebeneinander) ab ausreichender Breite, vierspaltige Schnellaktionen ab
    ausreichender Breite (sonst zweispaltig); Inhaltsbreite auf grossen
    Bildschirmen auf 960 px begrenzt.
  - **Wichtig – noch nicht dauerhaft gespeichert:** Termine, Aufgaben und
    Kontakte leben nur im laufenden App-Zustand von `RootShell`
    (`_appointments`/`_tasks`/`_contacts`), genau wie Rechnungsentwürfe.
    Nach einem vollständigen Neustart der App sind sie weg (siehe „Später
    geplant“).
  - Demo-Modus zeigt auf „Heute“ zusätzlich vollständig getrennte, klar als
    Beispiel erkennbare Demo-Termine/-Aufgaben/-Rechnungen, die nie den
    echten App-Zustand (insbesondere den Dokumente-Tab) berühren.
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
- **Dokumentstatus** (`lib/screens/documents/documents_screen.dart`,
  `lib/screens/documents/widgets/draft_list_tile.dart`): fünf Filter Alle/
  Entwürfe/Offen/Bezahlt/Überfällig, mit farbigen Status-Chips (Entwurf
  Grau/Beige, Offen Blau, Bezahlt Grün, Überfällig Rot) und animiertem
  Statuswechsel. Ein Entwurf erscheint nur unter „Alle“ und „Entwürfe“,
  niemals unter „Offen“. Über ein Aktionsmenü (⋮) an jeder Zeile kann ein
  Entwurf über „Rechnung stellen“ auf `open` gesetzt und danach über „Als
  bezahlt markieren“ auf `paid` gesetzt werden; eine bezahlte Rechnung kann
  mit Bestätigung wieder auf „Offen“ zurückgesetzt werden. „Überfällig“ ist
  keine eigene Statusoption, sondern wird immer aus `status == open` und
  dem abgelaufenen Fälligkeitsdatum abgeleitet. Rechnungsnummer, Empfänger,
  Datum und Betrag bleiben sichtbar; ein Dokument kann jederzeit erneut
  geöffnet und bearbeitet werden, ohne dabei dupliziert zu werden.
  Demo-Beispieldaten erscheinen ausschliesslich im Demo-Modus und
  beeinflussen nie den echten Dokumente-Tab.
- Begrenzte, zentrierte Inhaltsbreite auf grossen Bildschirmen, Formulare
  bleiben auf Smartphones gut bedienbar.

## Aktuell in Arbeit

- Nichts – dieser Checkpoint erneuert das visuelle Erscheinungsbild der
  Startseite „Heute“ vollständig (neues Weiss/Hellblau-Farbsystem, grosse
  Karten, animiertes Umsatzdiagramm, schwebende untere Navigation) und
  erweitert den Kalender um eine echte Monatsansicht mit freier
  Wochen-/Monatsnavigation, ohne bestehende Funktionen (Rechnungsstatus,
  Umsatzberechnung, Kontaktsuche, Aufgabenverwaltung) zu verändern.

## Später geplant

- Echte Authentifizierung und Backend-Anbindung (Login/Registrierung sind
  aktuell nur lokal klickbare Abläufe, kein echtes Benutzerkonto).
- Dauerhafte lokale Speicherung bzw. Backend für Firmeneinrichtung,
  Rechnungen, Termine, Aufgaben, Kontakte und das Firmenlogo (aktuell nur
  lokaler App-Zustand in `RootShell`, geht bei einem vollständigen Neustart
  der App verloren – für dauerhafte Speicherung würde das Logo z.B.
  zusätzlich als Datei im Anwendungsverzeichnis abgelegt und der Pfad
  persistiert werden müssen; Termine/Aufgaben/Kontakte bräuchten eine
  lokale Datenbank oder ein Backend). Die Modelle (`Appointment`,
  `TaskItem`, `InvoiceDraft`, `Contact`) sind bereits mit eindeutigen IDs
  versehen, damit eine spätere Speicherung ohne Datenmigration ergänzt
  werden kann.
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
- **Echte Kontaktverwaltung** für den „Kontakte“-Tab (aktuell nur
  Platzhalter): Kontakte anlegen/bearbeiten/löschen im UI („Kontakt
  hinzufügen“ auf „Heute“ ist bewusst deaktiviert, bis das existiert),
  Auswahl bereits gespeicherter Kontakte als Rechnungsempfänger (aktuell
  wird der Kunde pro Rechnung neu erfasst). Das `Contact`-Modell und die
  Verknüpfung von Terminen mit einem Kontakt (`Appointment.contactId`)
  existieren bereits als Grundlage (siehe oben, „Kontaktsuche im
  Termin-Dialog“) – für echte Konten bleibt die Kontaktliste aber leer,
  bis diese Verwaltung existiert.
- Inhalt für den „Assistent“-Tab (Konzept noch offen, kein KI-Assistent in
  dieser Version).
- „Offerte erstellen“ als echte Funktion (aktuell sichtbar als „Bald
  verfügbar“ deaktiviert).
- **Bankanbindung bzw. Open Banking, CAMT-Import und automatischer
  Zahlungsabgleich.** Eine App kann nicht allein anhand des erstellten
  QR-Codes erkennen, ob ein Zahlungseingang tatsächlich auf dem Bankkonto
  eingetroffen ist – dafür wäre eine echte Bankanbindung, eine
  Open-Banking-Schnittstelle oder ein CAMT-Import mit Backend nötig.
  Deshalb gilt aktuell bewusst: Bezahlung wird ausschliesslich manuell über
  „Als bezahlt markieren“ erfasst (`InvoiceDraft.status`/`paidAt`,
  Dokumente-Tab), Überfälligkeit wird automatisch anhand des Datums
  berechnet, und es werden nie simulierte oder erfundene Zahlungseingänge
  angezeigt. Ein Mahnwesen (automatische Zahlungserinnerungen) ist damit
  ebenfalls noch nicht umgesetzt.
- **Echter Gewinn** (Umsatz abzüglich Ausgaben) setzt zusätzlich eine
  Ausgabenerfassung voraus, die es noch nicht gibt; die App verwendet
  bewusst nirgends den Begriff „Gewinn“.
- **Frei wählbare Akzentfarbe**: Farben und Abstände sind zentral in
  `lib/theme/app_theme.dart` (`AppColors`, `AppSpacing`) gebündelt; ein
  Farbwähler selbst ist noch nicht implementiert.
- „Vertrag erstellen“ als echte Funktion für allgemeine Verträge (aktuell
  sichtbar als „Bald verfügbar“ deaktiviert, keinerlei Vertragslogik
  vorbereitet).
