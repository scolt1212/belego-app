import 'package:flutter/material.dart';

import '../../models/forderung.dart';
import '../../widgets/max_width_box.dart';
import 'widgets/demo_mode_banner.dart';
import 'widgets/empty_today_state.dart';
import 'widgets/open_forderungen_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.isDemoMode,
    required this.onCreateInvoice,
  });

  final bool isDemoMode;

  /// Öffnet den echten Rechnungseditor (nur ausserhalb des Demo-Modus genutzt).
  final VoidCallback onCreateInvoice;

  // Beispieldaten ausschliesslich für den Demo-Modus.
  static final List<Forderung> _demoForderungen = [
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diese Funktion folgt in einem späteren Schritt.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heute')),
      body: SafeArea(
        child: MaxWidthBox(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isDemoMode) ...[
                DemoModeBanner(onLeaveDemo: () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                OpenForderungenCard(forderungen: _demoForderungen),
              ] else
                EmptyTodayState(
                  onCreateInvoice: onCreateInvoice,
                  onCreateOffer: () => _showComingSoon(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
