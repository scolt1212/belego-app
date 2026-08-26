import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/company_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/iban.dart';
import '../../../utils/swiss_phone_number.dart';
import '../../../utils/swiss_vat_number.dart';
import 'company_logo_section.dart';

/// Schritt 3 der Firmeneinrichtung: Firmenlogo-Bereich und Zusammenfassung.
/// Zeigt ausschliesslich tatsächlich eingegebene Werte, keine erfundenen.
class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.profile,
    required this.onLogoChanged,
  });

  final CompanyProfile profile;
  final void Function(Uint8List? bytes, String? fileName) onLogoChanged;

  @override
  Widget build(BuildContext context) {
    final address =
        '${profile.street} ${profile.houseNumber}, '
        '${profile.postalCode} ${profile.city}, ${profile.country}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanyLogoSection(
          logoBytes: profile.logoBytes,
          logoFileName: profile.logoFileName,
          onLogoChanged: onLogoChanged,
        ),
        const SizedBox(height: 28),
        const Text(
          'Zusammenfassung',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow('Firmenname', profile.companyName),
                _SummaryRow(
                  'Ansprechperson',
                  '${profile.firstName} ${profile.lastName}',
                ),
                _SummaryRow('Adresse', address),
                _SummaryRow('Telefon', _phoneSummary(profile)),
                _SummaryRow('Geschäfts-E-Mail', profile.businessEmail),
                _SummaryRow('IBAN', Iban.formatForDisplay(profile.iban)),
                _SummaryRow(
                  'MWST-pflichtig',
                  profile.isVatLiable ? 'Ja' : 'Nein',
                ),
                if (profile.isVatLiable) ...[
                  _SummaryRow(
                    'MWST-Nummer',
                    SwissVatNumber.formatForDisplay(profile.vatNumber),
                  ),
                  _SummaryRow(
                    'Standard-MWST-Satz',
                    '${profile.vatRate.toStringAsFixed(1)} %',
                  ),
                ],
                _SummaryRow('Zahlungsfrist', '${profile.paymentTermDays} Tage'),
                _SummaryRow(
                  'Logo',
                  profile.hasLogo
                      ? 'Logo ausgewählt'
                      : 'Noch kein Logo ausgewählt',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _phoneSummary(CompanyProfile profile) {
    if (profile.country != 'Schweiz') return profile.phoneNumber;
    return SwissPhoneNumber.formatForDisplay(profile.phoneNumber);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  // Unterhalb dieser verfügbaren Breite werden Label und Wert untereinander
  // statt nebeneinander dargestellt, damit lange Werte auf kleinen
  // Bildschirmen umbrechen können statt überzulaufen.
  static const double _stackBreakpoint = 380;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidget = Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          );

          if (constraints.maxWidth < _stackBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: labelWidget),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
