import 'package:flutter/material.dart';

import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/max_width_box.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../root_shell.dart';

/// Erster Bildschirm, den ein Benutzer beim Start von Belego sieht.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.postalCodeService});

  final PostalCodeService postalCodeService;

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(postalCodeService: postalCodeService),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(postalCodeService: postalCodeService),
      ),
    );
  }

  void _openDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RootShell(isDemoMode: true, postalCodeService: postalCodeService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MaxWidthBox(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _Wordmark(),
                const SizedBox(height: 16),
                const Text(
                  'Dein Büro. Einfach erledigt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(flex: 4),
                ElevatedButton(
                  onPressed: () => _openRegister(context),
                  child: const Text('Kostenlos registrieren'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _openLogin(context),
                  child: const Text('Anmelden'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _openDemo(context),
                  child: const Text('Demo ansehen'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.sky50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sky100),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.sky600,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'belego',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
