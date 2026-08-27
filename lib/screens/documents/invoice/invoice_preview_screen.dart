import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/company_profile.dart';
import '../../../models/invoice_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/iban.dart';
import '../../../utils/money.dart';
import '../../../widgets/max_width_box.dart';

/// Einfache, bildschirmbasierte Vorschau eines Rechnungsentwurfs. Noch kein
/// PDF, noch kein Swiss-QR-Zahlteil (siehe ROADMAP.md).
class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.draft,
    required this.companyProfile,
  });

  final InvoiceDraft draft;
  final CompanyProfile companyProfile;

  static final DateFormat _swissDateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final companyIsVatLiable = companyProfile.isVatLiable;

    return Scaffold(
      appBar: AppBar(title: const Text('Vorschau')),
      body: SafeArea(
        child: MaxWidthBox(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sky100),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.sky600,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dies ist eine Vorschau – noch kein PDF, noch kein Versand.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sky600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Von',
                children: [
                  // Mit Logo erscheint dieses oben links, ohne Logo der
                  // Firmenname als Ersatz (siehe CLAUDE.md).
                  if (companyProfile.logoBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 160,
                          maxHeight: 80,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.memory(
                            companyProfile.logoBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    companyProfile.companyName.isEmpty
                        ? 'Deine Firma'
                        : companyProfile.companyName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${companyProfile.street} ${companyProfile.houseNumber}',
                  ),
                  Text(
                    '${companyProfile.postalCode} ${companyProfile.city}, ${companyProfile.country}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'An',
                children: [
                  Text(
                    draft.customer.displayName.isEmpty
                        ? '(kein Empfänger angegeben)'
                        : draft.customer.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${draft.customer.street} ${draft.customer.houseNumber}',
                  ),
                  Text(
                    '${draft.customer.postalCode} ${draft.customer.city}, ${draft.customer.country}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title:
                    'Rechnung ${draft.invoiceNumber ?? "(wird beim Speichern vergeben)"}',
                children: [
                  Text('Datum: ${_swissDateFormat.format(draft.invoiceDate)}'),
                  Text('Fällig am: ${_swissDateFormat.format(draft.dueDate)}'),
                  if (draft.title.isNotEmpty) Text('Titel: ${draft.title}'),
                  if (draft.introText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(draft.introText),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Positionen',
                children: [
                  for (final item in draft.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.description.isEmpty
                                  ? '(ohne Beschreibung)'
                                  : item.description,
                            ),
                          ),
                          Text('${item.quantity} ${item.unit}'),
                          const SizedBox(width: 12),
                          Text(Money.formatRappen(item.netAmountRappen)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Summe',
                children: [
                  _TotalLine(
                    'Zwischensumme',
                    Money.formatRappen(draft.subtotalRappen()),
                  ),
                  if (companyIsVatLiable)
                    _TotalLine(
                      'MWST',
                      Money.formatRappen(
                        draft.vatTotalRappen(companyIsVatLiable: true),
                      ),
                    ),
                  _TotalLine(
                    'Rechnungsbetrag',
                    Money.formatRappen(
                      draft.totalRappen(companyIsVatLiable: companyIsVatLiable),
                    ),
                    emphasized: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Bankangaben',
                children: [
                  Text('IBAN: ${Iban.formatForDisplay(companyProfile.iban)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stellt den Rechnungsinhalt bewusst neutral in Schwarz/Weiss/Grau dar,
/// unabhängig vom warmen Farbsystem der App-Oberfläche – diese Vorschau
/// entspricht später dem gedruckten PDF (siehe CLAUDE.md, „Rechnungen &
/// Offerten“).
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 10),
            DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFF202124)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine(this.label, this.value, {this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 15 : 13,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
