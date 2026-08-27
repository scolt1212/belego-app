import 'package:flutter/material.dart';

import '../../models/invoice_draft.dart';
import '../../theme/app_theme.dart';
import '../../widgets/max_width_box.dart';
import 'widgets/draft_list_tile.dart';

/// Filter für die Dokumentenliste. Wird u.a. von der Startseite verwendet,
/// um von den Finanzkarten „Offene Rechnungen“/„Überfällige Rechnungen“
/// direkt in die passend gefilterte Ansicht zu springen.
enum DocumentsFilter { all, draft, open, paid, overdue }

/// „Dokumente“-Tab: zeigt gespeicherte Rechnungen, gefiltert nach
/// fachlichem Status (Entwurf/Offen/Bezahlt) bzw. abgeleiteter
/// Überfälligkeit.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.drafts,
    required this.companyIsVatLiable,
    required this.onOpenDraft,
    required this.onChangeStatus,
    this.initialFilter = DocumentsFilter.all,
  });

  final List<InvoiceDraft> drafts;
  final bool companyIsVatLiable;
  final ValueChanged<InvoiceDraft> onOpenDraft;
  final void Function(InvoiceDraft draft, InvoiceStatus status) onChangeStatus;
  final DocumentsFilter initialFilter;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late DocumentsFilter _filter = widget.initialFilter;

  List<InvoiceDraft> get _filteredDrafts {
    switch (_filter) {
      case DocumentsFilter.all:
        return widget.drafts;
      case DocumentsFilter.draft:
        return widget.drafts
            .where((d) => d.status == InvoiceStatus.draft)
            .toList();
      case DocumentsFilter.open:
        return widget.drafts
            .where((d) => d.status == InvoiceStatus.open)
            .toList();
      case DocumentsFilter.paid:
        return widget.drafts
            .where((d) => d.status == InvoiceStatus.paid)
            .toList();
      case DocumentsFilter.overdue:
        return widget.drafts.where((d) => d.isOverdue).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDrafts;
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumente')),
      body: SafeArea(
        child: MaxWidthBox(
          child: widget.drafts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterChip(DocumentsFilter.all, 'Alle'),
                            _filterChip(DocumentsFilter.draft, 'Entwürfe'),
                            _filterChip(DocumentsFilter.open, 'Offen'),
                            _filterChip(DocumentsFilter.paid, 'Bezahlt'),
                            _filterChip(DocumentsFilter.overdue, 'Überfällig'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildFilterEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length + 1,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      filtered.length == 1
                                          ? '1 Dokument'
                                          : '${filtered.length} Dokumente',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                                final draft = filtered[index - 1];
                                return DraftListTile(
                                  draft: draft,
                                  companyIsVatLiable: widget.companyIsVatLiable,
                                  onTap: () => widget.onOpenDraft(draft),
                                  onChangeStatus: widget.onChangeStatus,
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _filterChip(DocumentsFilter filter, String label) {
    final selected = _filter == filter;
    return ChoiceChip(
      key: Key('documents_filter_${filter.name}'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: AppColors.sky100,
      labelStyle: TextStyle(
        color: selected ? AppColors.sky600 : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_off_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Keine Dokumente für diesen Filter.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _filter = DocumentsFilter.all),
              child: const Text('Alle anzeigen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.sky50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.sky600,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Noch keine Dokumente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gespeicherte Rechnungsentwürfe erscheinen hier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
