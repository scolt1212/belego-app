import 'package:flutter/material.dart';

import '../../../../models/invoice_draft.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/money.dart';

/// Abschnitt „Summenberechnung“: Zwischensumme, MWST (falls anwendbar) und
/// Rechnungsbetrag in CHF. Aktualisiert sich sofort mit den Positionen.
class InvoiceTotalsSummary extends StatelessWidget {
  const InvoiceTotalsSummary({
    super.key,
    required this.draft,
    required this.companyIsVatLiable,
  });

  final InvoiceDraft draft;
  final bool companyIsVatLiable;

  @override
  Widget build(BuildContext context) {
    final subtotal = draft.subtotalRappen();
    final vat = draft.vatTotalRappen(companyIsVatLiable: companyIsVatLiable);
    final total = draft.totalRappen(companyIsVatLiable: companyIsVatLiable);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sky50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalRow(
            label: 'Zwischensumme',
            value: Money.formatRappen(subtotal),
            fieldKey: const Key('invoice_subtotal'),
          ),
          if (companyIsVatLiable) ...[
            const SizedBox(height: 6),
            _TotalRow(
              label: 'MWST',
              value: Money.formatRappen(vat),
              fieldKey: const Key('invoice_vat_total'),
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          _TotalRow(
            label: 'Rechnungsbetrag',
            value: Money.formatRappen(total),
            emphasized: true,
            fieldKey: const Key('invoice_total_amount'),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.fieldKey,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Key fieldKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 16 : 13,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
      color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          key: fieldKey,
          style: style.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
