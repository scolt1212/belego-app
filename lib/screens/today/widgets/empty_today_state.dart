import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Leerer Zustand für den „Heute“-Screen eines neu registrierten Benutzers,
/// ohne fremde Beispieldaten.
class EmptyTodayState extends StatelessWidget {
  const EmptyTodayState({
    super.key,
    required this.onCreateInvoice,
    required this.onCreateOffer,
  });

  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateOffer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.sky50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppColors.sky600,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Noch keine offenen Forderungen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Erstelle deine erste Rechnung oder Offerte.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('empty_today_create_invoice'),
              onPressed: onCreateInvoice,
              child: const Text('Rechnung erstellen'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('empty_today_create_offer'),
              onPressed: onCreateOffer,
              child: const Text('Offerte erstellen'),
            ),
          ),
        ],
      ),
    );
  }
}
