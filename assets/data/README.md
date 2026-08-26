# Schweizer PLZ-/Ortschaftsdaten

Datei: `swiss_postal_codes.json`

## Quelle

Amtliches Ortschaftenverzeichnis mit Postleitzahl und Perimeter (PLZO) des
Bundesamts für Landestopografie swisstopo, im Auftrag gemäss Art. 24 GeoNV
geführt. Offiziell und kostenlos verfügbar als Open Government Data (OGD).

- Produktseite: https://www.swisstopo.admin.ch/de/amtliches-ortschaftenverzeichnis
- Direkt bezogen über die STAC-API von data.geo.admin.ch, Collection
  `ch.swisstopo-vd.ortschaftenverzeichnis_plz`, Asset
  `ortschaftenverzeichnis_plz_2056.csv.zip`
  (`https://data.geo.admin.ch/ch.swisstopo-vd.ortschaftenverzeichnis_plz/ortschaftenverzeichnis_plz/ortschaftenverzeichnis_plz_2056.csv.zip`).
- Nutzungsbedingungen: swisstopo „Nutzungsbedingungen für kostenlose Geodaten
  und Geodienste des Bundes“.

## Abrufdatum

2026-08-25

## Verarbeitung

Aus der Original-CSV (`AMTOVZ_CSV_LV95.csv`, Spalten u.a. `Ortschaftsname`,
`PLZ4`, `Zusatzziffer`, `Gemeindename`, `Kantonskürzel`) wurde eine kompakte
JSON-Liste erzeugt:

- Nur die Felder `postalCode` (PLZ4), `locality` (Ortschaftsname) und
  `canton` (Kantonskürzel) werden übernommen.
- Doppelte, identische Kombinationen aus `postalCode` + `locality` +
  `canton` (z.B. durch mehrere Gemeinde-Adressenanteile pro PLZ) wurden
  entfernt.
- Keine Postleitzahlen oder Ortsnamen wurden erfunden oder verändert – die
  Werte entsprechen exakt der amtlichen Quelle.
- Sortiert nach PLZ, dann Ortsname.
- Ergebnis: 4'245 eindeutige PLZ-/Ort-Kombinationen (Stand Abrufdatum).

## Format

```json
[{"postalCode":"8340","locality":"Hinwil","canton":"ZH"}, ...]
```

## Aktualisierung

Um die Daten zu aktualisieren, das Asset erneut über die oben genannte
STAC-API beziehen, entpacken und mit demselben Verfahren (Felder
extrahieren, deduplizieren, sortieren) neu erzeugen. Die Suchlogik in
`lib/services/postal_code_service.dart` muss dafür nicht angepasst werden.
