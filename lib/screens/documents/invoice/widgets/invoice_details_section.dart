import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_theme.dart';
import '../../../../utils/validators.dart';

/// Abschnitt „Rechnungsangaben“: Nummer, Datum, Zahlungsfrist,
/// Fälligkeitsdatum, Titel und Einleitungstext.
class InvoiceDetailsSection extends StatelessWidget {
  const InvoiceDetailsSection({
    super.key,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.onInvoiceDateChanged,
    required this.paymentTermController,
    required this.dueDate,
    required this.titleController,
    required this.introTextController,
  });

  /// `null`, solange die Rechnung noch nie gespeichert wurde – die Nummer
  /// wird erst beim ersten Speichern fest vergeben.
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final ValueChanged<DateTime> onInvoiceDateChanged;
  final TextEditingController paymentTermController;
  final DateTime dueDate;
  final TextEditingController titleController;
  final TextEditingController introTextController;

  static final DateFormat _swissDateFormat = DateFormat('dd.MM.yyyy');

  Future<void> _pickInvoiceDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(invoiceDate.year - 5),
      lastDate: DateTime(invoiceDate.year + 5),
    );
    if (picked != null) onInvoiceDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rechnungsangaben',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _AutoField(
          label: 'Rechnungsnummer',
          value: invoiceNumber ?? 'Wird beim Speichern vergeben',
          caption: 'Automatisch vergeben',
          fieldKey: const Key('invoice_number'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                key: const Key('invoice_date_picker'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pickInvoiceDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Rechnungsdatum',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(_swissDateFormat.format(invoiceDate)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('invoice_payment_term'),
                controller: paymentTermController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zahlungsfrist (Tage)',
                ),
                validator: Validators.positiveInteger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AutoField(
          label: 'Fälligkeitsdatum',
          value: _swissDateFormat.format(dueDate),
          caption: 'Automatisch berechnet',
          fieldKey: const Key('invoice_due_date'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('invoice_title'),
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titel oder Projekt (optional)',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('invoice_intro_text'),
          controller: introTextController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Einleitungstext (optional)',
          ),
        ),
      ],
    );
  }
}

/// Optisch klar von editierbaren Feldern unterscheidbare Darstellung für
/// automatisch vergebene/berechnete Werte (grauer Hintergrund, Schloss-Symbol,
/// kein Rand im Sky-Fokus-Stil).
class _AutoField extends StatelessWidget {
  const _AutoField({
    required this.label,
    required this.value,
    required this.caption,
    required this.fieldKey,
  });

  final String label;
  final String value;
  final String caption;
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: fieldKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.autoFieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
