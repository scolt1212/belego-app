# Belego – Roadmap

## Bereits erledigt

- Grundgerüst der App: Theme mit Sky-Blau-Akzent auf Weiss/Grau
  (`lib/theme/app_theme.dart`).
- Tab-Navigation mit 4 Tabs (Heute, Assistent, Dokumente, Kontakte) via
  `IndexedStack` + `BottomNavigationBar` (`lib/screens/root_shell.dart`).
- „Heute“-Screen mit Karte „Offene Forderungen“, inkl. Mockdaten und
  CHF-Formatierung (`lib/screens/today/`).
- Platzhalter-Screens für Assistent, Dokumente, Kontakte.
- Technik-/Designregeln in `CLAUDE.md` festgehalten.

## Aktuell in Arbeit

- Nichts – dieser Checkpoint schliesst die Grundstruktur ab.

## Später geplant

- Inhalt für den „Assistent“-Tab (Konzept noch offen).
- Inhalt für den „Dokumente“-Tab (Belege erfassen/anzeigen).
- Inhalt für den „Kontakte“-Tab (Kunden/Lieferanten verwalten).
- Anbindung „Offene Forderungen“ an echte Daten statt Mockdaten.
- Persistenz/Backend-Anbindung (noch nicht festgelegt).
- Weitere Karten auf dem „Heute“-Screen (z.B. offene Aufgaben, letzte
  Aktivitäten) – nach Bedarf.
