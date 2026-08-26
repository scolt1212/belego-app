import 'package:flutter/material.dart';

import '../../../models/invoice_line_item.dart' show vatRateOptions;
import '../../../theme/app_theme.dart';
import '../../../utils/validators.dart';

/// Schritt 2 der Firmeneinrichtung: Finanzangaben.
class FinanceStep extends StatelessWidget {
  const FinanceStep({
    super.key,
    required this.formKey,
    required this.ibanController,
    required this.isVatLiable,
    required this.onVatLiableChanged,
    required this.vatNumberController,
    required this.vatRate,
    required this.onVatRateChanged,
    required this.paymentTermController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController ibanController;
  final bool isVatLiable;
  final ValueChanged<bool> onVatLiableChanged;
  final TextEditingController vatNumberController;
  final double vatRate;
  final ValueChanged<double> onVatRateChanged;
  final TextEditingController paymentTermController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('setup_iban'),
            controller: ibanController,
            decoration: const InputDecoration(
              labelText: 'IBAN',
              helperText: 'Für Überweisungen an dein Geschäftskonto.',
              helperMaxLines: 2,
            ),
            validator: Validators.iban,
          ),
          const SizedBox(height: 20),
          const Text(
            'MWST-pflichtig',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: const Key('setup_vat_liable'),
            segments: const [
              ButtonSegment(value: true, label: Text('Ja')),
              ButtonSegment(value: false, label: Text('Nein')),
            ],
            selected: {isVatLiable},
            onSelectionChanged: (selection) =>
                onVatLiableChanged(selection.first),
          ),
          if (isVatLiable) ...[
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('setup_vat_number'),
              controller: vatNumberController,
              decoration: const InputDecoration(
                labelText: 'MWST-Nummer',
                hintText: 'CHE-123.456.789 MWST',
              ),
              validator: Validators.vatNumber,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              key: const Key('setup_vat_rate'),
              initialValue: vatRate,
              decoration: const InputDecoration(
                labelText: 'Standard-MWST-Satz',
              ),
              items: [
                for (final rate in vatRateOptions)
                  DropdownMenuItem(
                    value: rate,
                    child: Text('${rate.toStringAsFixed(1)} %'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onVatRateChanged(value);
              },
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('setup_payment_term'),
            controller: paymentTermController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Standard-Zahlungsfrist (Tage)',
            ),
            validator: Validators.positiveInteger,
          ),
        ],
      ),
    );
  }
}
