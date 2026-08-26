import 'package:flutter/material.dart';

import '../../../../models/invoice_line_item.dart';
import '../../../../theme/app_theme.dart';
import 'invoice_line_item_row.dart';

/// Abschnitt „Rechnungspositionen“: Liste der Positionen plus
/// „Position hinzufügen“.
class InvoiceLineItemsSection extends StatelessWidget {
  const InvoiceLineItemsSection({
    super.key,
    required this.items,
    required this.controllers,
    required this.companyIsVatLiable,
    required this.onItemChanged,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  final List<InvoiceLineItem> items;
  final List<LineItemControllers> controllers;
  final bool companyIsVatLiable;
  final VoidCallback onItemChanged;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rechnungspositionen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        const Text(
          '* Pflichtfeld, alle anderen Felder sind optional.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          InvoiceLineItemRow(
            index: i,
            item: items[i],
            controllers: controllers[i],
            companyIsVatLiable: companyIsVatLiable,
            // "Position 1" bleibt immer bestehen; ab Position 2 kann
            // entfernt werden.
            canRemove: i > 0,
            onChanged: onItemChanged,
            onRemove: () => onRemoveItem(i),
          ),
        OutlinedButton.icon(
          key: const Key('invoice_add_item'),
          onPressed: onAddItem,
          icon: const Icon(Icons.add),
          label: const Text('Position hinzufügen'),
        ),
      ],
    );
  }
}
