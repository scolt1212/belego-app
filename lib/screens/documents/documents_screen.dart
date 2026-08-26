import 'package:flutter/material.dart';

import '../../models/invoice_draft.dart';
import '../../theme/app_theme.dart';
import '../../widgets/max_width_box.dart';
import 'widgets/draft_list_tile.dart';

/// „Dokumente“-Tab: zeigt gespeicherte Rechnungsentwürfe. Ein Entwurf ist
/// noch keine offene Forderung und erscheint nicht auf dem „Heute“-Screen.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({
    super.key,
    required this.drafts,
    required this.companyIsVatLiable,
    required this.onOpenDraft,
  });

  final List<InvoiceDraft> drafts;
  final bool companyIsVatLiable;
  final ValueChanged<InvoiceDraft> onOpenDraft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumente')),
      body: SafeArea(
        child: MaxWidthBox(
          child: drafts.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: drafts.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          drafts.length == 1
                              ? '1 Entwurf'
                              : '${drafts.length} Entwürfe',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    final draft = drafts[index - 1];
                    return DraftListTile(
                      draft: draft,
                      companyIsVatLiable: companyIsVatLiable,
                      onTap: () => onOpenDraft(draft),
                    );
                  },
                ),
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
