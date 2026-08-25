import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const BelegoApp());
}

class BelegoApp extends StatelessWidget {
  const BelegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Belego',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}
