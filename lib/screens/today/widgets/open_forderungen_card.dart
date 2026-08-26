import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/forderung.dart';
import '../../../theme/app_theme.dart';

/// Karte auf dem "Heute"-Screen, die offene Forderungen zusammenfasst.
class OpenForderungenCard extends StatelessWidget {
  const OpenForderungenCard({super.key, required this.forderungen});

  final List<Forderung> forderungen;

  double get _gesamtBetrag =>
      forderungen.fold(0, (summe, f) => summe + f.betrag);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'de_CH',
      symbol: 'CHF',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, currencyFormat),
            if (forderungen.isEmpty)
              _buildEmptyState()
            else ...[
              const SizedBox(height: 12),
              for (final forderung in forderungen) ...[
                _ForderungRow(forderung: forderung, format: currencyFormat),
                if (forderung != forderungen.last)
                  const Divider(height: 20, color: AppColors.border),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.sky600,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Alle anzeigen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NumberFormat format) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sky50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.sky600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offene Forderungen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                '${forderungen.length} unbezahlte ${forderungen.length == 1 ? 'Rechnung' : 'Rechnungen'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          format.format(_gesamtBetrag),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        'Keine offenen Forderungen – alles ist bezahlt.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _ForderungRow extends StatelessWidget {
  const _ForderungRow({required this.forderung, required this.format});

  final Forderung forderung;
  final NumberFormat format;

  @override
  Widget build(BuildContext context) {
    final ueberfaellig = forderung.istUeberfaellig;
    final tage = forderung.tageDifferenz.abs();
    final faelligkeitsLabel = ueberfaellig
        ? 'Überfällig seit $tage ${tage == 1 ? 'Tag' : 'Tagen'}'
        : (tage == 0
              ? 'Heute fällig'
              : 'Fällig in $tage ${tage == 1 ? 'Tag' : 'Tagen'}');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forderung.kontaktName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                forderung.belegNummer,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              format.format(forderung.betrag),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ueberfaellig ? AppColors.dangerBg : AppColors.sky50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                faelligkeitsLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ueberfaellig ? AppColors.danger : AppColors.sky600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
