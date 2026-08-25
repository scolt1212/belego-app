import 'package:flutter/material.dart';

import '../../models/forderung.dart';
import 'widgets/open_forderungen_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  // Platzhalter-Daten, bis die Anbindung an echte Belege erfolgt.
  static final List<Forderung> _mockForderungen = [
    Forderung(
      kontaktName: 'Müller Bau GmbH',
      betrag: 1240.00,
      faelligkeitsdatum: DateTime.now().subtract(const Duration(days: 4)),
      belegNummer: 'RE-2026-0142',
    ),
    Forderung(
      kontaktName: 'Anna Schneider',
      betrag: 380.50,
      faelligkeitsdatum: DateTime.now().add(const Duration(days: 2)),
      belegNummer: 'RE-2026-0156',
    ),
    Forderung(
      kontaktName: 'Café Sonnenblick',
      betrag: 95.00,
      faelligkeitsdatum: DateTime.now().add(const Duration(days: 6)),
      belegNummer: 'RE-2026-0159',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heute')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OpenForderungenCard(forderungen: _mockForderungen),
          ],
        ),
      ),
    );
  }
}
