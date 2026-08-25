# Belego – Technik- und Designregeln

Verbindliche Grundregeln für dieses Projekt. Bei Unsicherheit gelten diese
Regeln, bis der Nutzer sie ausdrücklich ändert.

## Technik

- **Framework:** Flutter, Zielplattformen Android, iOS und Web.
- **State-Management:** vorläufig einfaches `setState` / `StatefulWidget`.
  Kein Provider, Riverpod, Bloc o.ä., solange nicht ausdrücklich gewünscht.
- **Navigation:** `IndexedStack` + `BottomNavigationBar`, kein Routing-Paket
  (kein `go_router`) ohne ausdrücklichen Auftrag.
- **Abhängigkeiten:** so wenig Zusatzpakete wie möglich. Neue Pakete nur
  hinzufügen, wenn es ohne sie unverhältnismässig aufwändig würde – und dann
  kurz begründen.

## Design

- **Akzentfarbe:** ausschliesslich Sky-Blau (Tailwind `sky-500` `#0EA5E9`
  und `sky-600` `#0284C7`). Kein weiterer Akzent- oder Markenfarbton.
- **Hintergrund/Flächen:** Weiss und neutrale Grautöne (siehe
  `lib/theme/app_theme.dart`, `AppColors`). Keine weiteren Buntfarben ausser
  für semantische Zustände (z.B. Rot für überfällig).
- **Struktur:** vier Tabs unten – Heute, Assistent, Dokumente, Kontakte.
  Neue Hauptfunktionen werden diesen vier Tabs zugeordnet, nicht als
  zusätzlicher fünfter Tab.

## Sprache & Format

- **Schreibweise:** Schweizer Hochdeutsch (kein „ß“, stattdessen „ss“).
- **Währung:** ausschliesslich CHF, Schweizer Zahlenformat (Apostroph als
  Tausendertrennzeichen, z.B. `CHF 1'240.00`).
  In Code: `NumberFormat.currency(locale: 'de_CH', symbol: 'CHF')`.
- **Datum:** Schweizer Format (`dd.MM.yyyy`).

## Sonstiges

- Rückfragen stellen, bevor bei mehrdeutigen Anforderungen grössere
  Architektur- oder Design-Entscheidungen getroffen werden.
- Siehe `ROADMAP.md` für erledigte, laufende und geplante Funktionen.
