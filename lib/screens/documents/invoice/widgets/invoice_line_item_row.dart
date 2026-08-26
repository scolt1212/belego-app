import 'package:flutter/material.dart';

import '../../../../models/invoice_line_item.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/money.dart';
import '../../../../utils/validators.dart';

/// Text-Controller für eine einzelne Rechnungsposition. Wird parallel zur
/// zugehörigen [InvoiceLineItem] gehalten und muss von der Elternseite
/// disposed werden.
class LineItemControllers {
  LineItemControllers(InvoiceLineItem item)
    : descriptionController = TextEditingController(text: item.description),
      detailController = TextEditingController(text: item.detail),
      quantityController = TextEditingController(
        text: _formatQuantity(item.quantity),
      ),
      unitPriceController = TextEditingController(
        text: (item.unitPriceRappen / 100).toStringAsFixed(2),
      );

  final TextEditingController descriptionController;
  final TextEditingController detailController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toString();
  }

  void dispose() {
    descriptionController.dispose();
    detailController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

/// Eine einzelne Rechnungsposition im Editor.
class InvoiceLineItemRow extends StatelessWidget {
  const InvoiceLineItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.controllers,
    required this.companyIsVatLiable,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final InvoiceLineItem item;
  final LineItemControllers controllers;
  final bool companyIsVatLiable;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('invoice_item_$index'),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Position ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  key: Key('invoice_item_remove_$index'),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Position entfernen',
                ),
            ],
          ),
          TextFormField(
            key: Key('invoice_item_description_$index'),
            controller: controllers.descriptionController,
            decoration: const InputDecoration(labelText: 'Beschreibung *'),
            validator: (v) =>
                Validators.required(v, message: 'Bitte Beschreibung eingeben'),
            onChanged: (v) {
              item.description = v;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: Key('invoice_item_detail_$index'),
            controller: controllers.detailController,
            decoration: const InputDecoration(
              labelText: 'Detailbeschreibung (optional)',
            ),
            onChanged: (v) => item.detail = v,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('invoice_item_quantity_$index'),
                  controller: controllers.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Menge *'),
                  validator: Validators.positiveDecimal,
                  onChanged: (v) {
                    final parsed = double.tryParse(
                      v.trim().replaceAll(',', '.'),
                    );
                    if (parsed != null && parsed > 0) item.quantity = parsed;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: Key('invoice_item_unit_$index'),
                  initialValue: item.unit,
                  decoration: const InputDecoration(labelText: 'Einheit *'),
                  items: [
                    for (final unit in invoiceUnits)
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    item.unit = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('invoice_item_unit_price_$index'),
                  controller: controllers.unitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Einzelpreis (CHF) *',
                  ),
                  validator: Validators.chfAmount,
                  onChanged: (v) {
                    final rappen = Money.parseChfToRappen(v);
                    if (rappen != null) item.unitPriceRappen = rappen;
                    onChanged();
                  },
                ),
              ),
              if (companyIsVatLiable) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    key: Key('invoice_item_vat_rate_$index'),
                    initialValue: item.vatRate,
                    decoration: const InputDecoration(labelText: 'MWST-Satz'),
                    items: [
                      for (final rate in vatRateOptions)
                        DropdownMenuItem(
                          value: rate,
                          child: Text('${rate.toStringAsFixed(1)} %'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      item.vatRate = value;
                      onChanged();
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Betrag: ${Money.formatRappen(item.netAmountRappen)}',
              key: Key('invoice_item_amount_$index'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
