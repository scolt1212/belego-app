import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/start/start_screen.dart';
import 'services/postal_code_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Deutschsprachige Datumsnamen (z.B. „Mittwoch, 26. August 2026“) sowie
  // die integrierten Datum-/Zeitauswahl-Dialoge benötigen einmalig
  // geladene Locale-Daten.
  await initializeDateFormatting('de_CH');
  // Amtliche Schweizer PLZ-/Ortschaftsdaten einmalig laden (siehe
  // assets/data/README.md), danach läuft die Suche rein lokal/offline.
  final postalCodeEntries = await PostalCodeService.loadEntriesFromAsset();
  final postalCodeService = PostalCodeService(entries: postalCodeEntries);
  runApp(BelegoApp(postalCodeService: postalCodeService));
}

class BelegoApp extends StatelessWidget {
  const BelegoApp({super.key, required this.postalCodeService});

  final PostalCodeService postalCodeService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Belego',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('de', 'CH'),
      supportedLocales: const [Locale('de', 'CH'), Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StartScreen(postalCodeService: postalCodeService),
    );
  }
}
