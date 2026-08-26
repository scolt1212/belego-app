import 'package:flutter/material.dart';

import 'screens/start/start_screen.dart';
import 'services/postal_code_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: StartScreen(postalCodeService: postalCodeService),
    );
  }
}
