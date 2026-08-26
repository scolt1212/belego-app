import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/invoice_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/money.dart';

/// Eine Zeile in der Dokumentenliste für einen gespeicherten Rechnungsentwurf.
class DraftListTile extends StatelessWidget {
  const DraftListTile({
    super.key,
    required this.draft,
    required this.companyIsVatLiable,
    required this.onTap,
  });

  final InvoiceDraft draft;
  final bool companyIsVatLiable;
  final VoidCallback onTap;

  static final DateFormat _swissDateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sky50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Entwurf',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          draft.invoiceNumber ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      draft.customer.displayName.isEmpty
                          ? '(kein Empfänger angegeben)'
                          : draft.customer.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _swissDateFormat.format(draft.invoiceDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Money.formatRappen(
                  draft.totalRappen(companyIsVatLiable: companyIsVatLiable),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
