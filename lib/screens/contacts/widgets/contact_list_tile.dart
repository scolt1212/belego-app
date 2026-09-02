import 'package:flutter/material.dart';

import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pressable.dart';

/// Eine Kontaktkarte in der Kontaktliste: Name (bei Firmen mit optionaler
/// Ansprechperson darunter), gut sichtbare Kategorie-Chips (Kunde = Blau,
/// Lieferant = Orange, beide gleichzeitig klar erkennbar nebeneinander),
/// kompakte Adresse und – nur falls vorhanden – Telefon/E-Mail. Die gesamte
/// Karte ist antippbar und öffnet die Detailseite; kein zusätzlicher
/// „Öffnen“-Button nötig.
class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  final Contact contact;
  final VoidCallback onTap;

  /// Telefon/E-Mail zusammen, aber nur die tatsächlich vorhandenen – keine
  /// leeren Platzhalterzeilen.
  String get _contactLine {
    final parts = <String>[
      if (contact.phone.isNotEmpty) contact.phone,
      if (contact.email.isNotEmpty) contact.email,
    ];
    return parts.join(' · ');
  }

  String get _initials {
    final name = contact.displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final showContactPerson =
        contact.isCompany && contact.contactPersonName.isNotEmpty;
    final contactLine = _contactLine;

    return Semantics(
      button: true,
      label:
          '${contact.displayName}${contact.isArchived ? ', archiviert' : ''}',
      child: Pressable(
        key: Key('contact_tile_${contact.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.sky100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: AppColors.sky600,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName.isEmpty
                            ? '(ohne Namen)'
                            : contact.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (showContactPerson)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            contact.contactPersonName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (contact.isCustomer)
                            const _CategoryChip(
                              label: 'Kunde',
                              color: AppColors.sky600,
                              bg: AppColors.sky100,
                            ),
                          if (contact.isSupplier)
                            const _CategoryChip(
                              label: 'Lieferant',
                              color: AppColors.privateOrange,
                              bg: AppColors.privateOrangeBg,
                            ),
                          if (contact.isArchived)
                            const _CategoryChip(
                              label: 'Archiviert',
                              color: AppColors.draftGrey,
                              bg: AppColors.draftGreyBg,
                            ),
                        ],
                      ),
                      if (contact.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          contact.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (contactLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          contactLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
