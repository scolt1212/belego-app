import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/invoice_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/money.dart';

/// Eine Zeile in der Dokumentenliste für eine gespeicherte Rechnung.
class DraftListTile extends StatelessWidget {
  const DraftListTile({
    super.key,
    required this.draft,
    required this.companyIsVatLiable,
    required this.onTap,
    required this.onChangeStatus,
  });

  final InvoiceDraft draft;
  final bool companyIsVatLiable;
  final VoidCallback onTap;

  /// Ändert den Status der Rechnung (siehe [_StatusMenu] für die je nach
  /// aktuellem Status sinnvollen Übergänge).
  final void Function(InvoiceDraft draft, InvoiceStatus status) onChangeStatus;

  static final DateFormat _swissDateFormat = DateFormat('dd.MM.yyyy');

  Future<void> _handleStatusSelected(
    BuildContext context,
    InvoiceStatus status,
  ) async {
    if (draft.status == InvoiceStatus.paid && status == InvoiceStatus.open) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Zurück auf „Offen“ setzen?'),
          content: Text(
            'Rechnung ${draft.invoiceNumber} gilt danach wieder als '
            'unbezahlt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    onChangeStatus(draft, status);
  }

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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _StatusBadge(draft: draft),
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
              _StatusMenu(
                draft: draft,
                onSelected: (status) => _handleStatusSelected(context, status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.draft});

  final InvoiceDraft draft;

  ({String label, Color fg, Color bg}) get _appearance {
    if (draft.isOverdue) {
      return (
        label: 'Überfällig',
        fg: AppColors.danger,
        bg: AppColors.dangerBg,
      );
    }
    switch (draft.status) {
      case InvoiceStatus.draft:
        return (
          label: 'Entwurf',
          fg: AppColors.textSecondary,
          bg: AppColors.autoFieldFill,
        );
      case InvoiceStatus.open:
        return (label: 'Offen', fg: AppColors.sky600, bg: AppColors.sky50);
      case InvoiceStatus.paid:
        return (
          label: 'Bezahlt',
          fg: AppColors.paidGreen,
          bg: AppColors.paidGreenBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _appearance;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey('${draft.status}-${draft.isOverdue}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: appearance.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          appearance.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: appearance.fg,
          ),
        ),
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.draft, required this.onSelected});

  final InvoiceDraft draft;
  final ValueChanged<InvoiceStatus> onSelected;

  List<PopupMenuEntry<InvoiceStatus>> _items() {
    switch (draft.status) {
      case InvoiceStatus.draft:
        return const [
          PopupMenuItem(
            value: InvoiceStatus.open,
            child: Text('Rechnung stellen'),
          ),
        ];
      case InvoiceStatus.open:
        return const [
          PopupMenuItem(
            value: InvoiceStatus.paid,
            child: Text('Als bezahlt markieren'),
          ),
        ];
      case InvoiceStatus.paid:
        return const [
          PopupMenuItem(
            value: InvoiceStatus.open,
            child: Text('Als offen markieren'),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<InvoiceStatus>(
      key: Key('draft_status_menu_${draft.invoiceNumber}'),
      tooltip: 'Status ändern',
      onSelected: onSelected,
      itemBuilder: (context) => _items(),
      icon: const Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }
}
