import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/iban.dart';
import '../../utils/swiss_phone_number.dart';
import '../../widgets/max_width_box.dart';
import '../today/widgets/quick_actions_section.dart';
import 'contact_editor_screen.dart';

/// Detailansicht eines Kontakts: Kopfkarte, Schnellaktionen (nur
/// tatsächlich funktionierende – „Bearbeiten“, bei Kunden „Rechnung
/// erstellen“, „Termin erstellen“), danach Adresse/Kontaktdaten/
/// Zahlungsangaben/Notiz als eigene Karten (nur wenn Daten vorhanden sind),
/// zuletzt bewusst zurückhaltendes Löschen/Archivieren.
class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({
    super.key,
    required this.contact,
    required this.postalCodeService,
    required this.isContactInUse,
    required this.onUpdate,
    required this.onDelete,
    required this.onCreateInvoice,
    required this.onCreateAppointment,
  });

  final Contact contact;
  final PostalCodeService postalCodeService;
  final bool isContactInUse;
  final ValueChanged<Contact> onUpdate;
  final ValueChanged<Contact> onDelete;

  /// Öffnet den Rechnungseditor, vorausgefüllt mit diesem Kontakt.
  final ValueChanged<Contact> onCreateInvoice;

  /// Öffnet den Termin-Dialog, vorverknüpft mit diesem Kontakt.
  final ValueChanged<Contact> onCreateAppointment;

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => ContactEditorScreen(
          postalCodeService: postalCodeService,
          existing: contact,
        ),
      ),
    );
    if (result != null) {
      onUpdate(result);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final willArchive = isContactInUse;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(willArchive ? 'Kontakt archivieren?' : 'Kontakt löschen?'),
        content: Text(
          willArchive
              ? '„${contact.displayName}“ wird bereits in mindestens einer '
                    'Rechnung oder einem Termin verwendet und deshalb '
                    'archiviert statt gelöscht. Bestehende Dokumente und '
                    'Termine bleiben unverändert; der Kontakt erscheint aber '
                    'nicht mehr in Auswahllisten für neue Dokumente.'
              : 'Möchtest du „${contact.displayName}“ wirklich endgültig '
                    'löschen? Das kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            key: const Key('contact_delete_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(willArchive ? 'Archivieren' : 'Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onDelete(contact);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _reactivate(BuildContext context) {
    contact.isArchived = false;
    onUpdate(contact);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Nur tatsächlich funktionierende Schnellaktionen – kein „Anrufen“/
    // „E-Mail“, da das ohne eine neue Paketabhängigkeit (z.B. url_launcher)
    // auf Android/iOS/Web nicht zuverlässig umsetzbar ist (siehe
    // Abschlussbericht/ROADMAP.md).
    final quickActions = <QuickAction>[
      QuickAction(
        actionKey: const Key('contact_action_edit'),
        icon: Icons.edit_outlined,
        label: 'Bearbeiten',
        enabled: true,
        onTap: () => _edit(context),
      ),
      if (contact.isCustomer)
        QuickAction(
          actionKey: const Key('contact_action_create_invoice'),
          icon: Icons.receipt_long_outlined,
          label: 'Rechnung erstellen',
          enabled: true,
          onTap: () => onCreateInvoice(contact),
        ),
      QuickAction(
        actionKey: const Key('contact_action_create_appointment'),
        icon: Icons.event_outlined,
        label: 'Termin erstellen',
        enabled: true,
        accentColor: AppColors.privateOrange,
        onTap: () => onCreateAppointment(contact),
      ),
    ];

    final hasAddress = contact.address.isNotEmpty;
    final hasContactData = contact.phone.isNotEmpty || contact.email.isNotEmpty;
    // IBAN nur zeigen, wenn vorhanden UND für die Rolle relevant – ein
    // reiner Kunde bekommt sie nicht mehr angezeigt, selbst wenn früher (z.B.
    // als Lieferant) einmal eine erfasst wurde; der Wert bleibt dabei
    // unangetastet gespeichert (siehe `ContactEditorScreen`).
    final hasPayment = contact.iban.isNotEmpty && contact.isSupplier;
    final hasNote = contact.note.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contact.displayName.isEmpty ? '(ohne Namen)' : contact.displayName,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (contact.isArchived)
                  Container(
                    key: const Key('contact_archived_banner'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.draftGreyBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 18,
                          color: AppColors.draftGrey,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dieser Kontakt ist archiviert und erscheint '
                            'nicht mehr in Auswahllisten für neue Dokumente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.draftGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Kopfkarte
                _HeaderCard(contact: contact),

                // 2. Schnellaktionen
                const SizedBox(height: 20),
                QuickActionsSection(actions: quickActions),

                // 3. Adresse
                if (hasAddress) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.place_outlined,
                    title: 'Adresse',
                    child: Text(
                      contact.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                // 4. Kontaktdaten
                if (hasContactData) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.contact_page_outlined,
                    title: 'Kontaktdaten',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contact.phone.isNotEmpty)
                          _DetailRow(
                            icon: Icons.call_outlined,
                            text: SwissPhoneNumber.formatForDisplay(
                              contact.phone,
                            ),
                          ),
                        if (contact.email.isNotEmpty)
                          _DetailRow(
                            icon: Icons.mail_outline,
                            text: contact.email,
                          ),
                      ],
                    ),
                  ),
                ],

                // 5. Zahlungsangaben
                if (hasPayment) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Zahlungsangaben',
                    child: _DetailRow(
                      icon: Icons.account_balance_outlined,
                      text: Iban.formatForDisplay(contact.iban),
                      showIcon: false,
                    ),
                  ),
                ],

                // 6. Notiz
                if (hasNote) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'Notiz',
                    child: Text(
                      contact.note,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                if (contact.isArchived) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      key: const Key('contact_reactivate_button'),
                      onPressed: () => _reactivate(context),
                      icon: const Icon(Icons.unarchive_outlined, size: 18),
                      label: const Text('Reaktivieren'),
                    ),
                  ),
                ],

                // 7. Löschen/Archivieren – bewusst zurückhaltend, nicht so
                // betont wie die Schnellaktionen oben (siehe Auftrag
                // „Kontakte“, Abschnitt „Bearbeiten, Löschen und
                // Archivieren“).
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    key: const Key('contact_delete_button'),
                    onPressed: () => _confirmDelete(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: Icon(
                      isContactInUse
                          ? Icons.archive_outlined
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    label: Text(isContactInUse ? 'Archivieren' : 'Löschen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.contact});

  final Contact contact;

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.sky100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppColors.sky600,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName.isEmpty
                      ? '(ohne Namen)'
                      : contact.displayName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showContactPerson)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      contact.contactPersonName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (contact.isCustomer)
                      const _CategoryBadge(
                        label: 'Kunde',
                        color: AppColors.sky600,
                        bg: AppColors.sky100,
                      ),
                    if (contact.isSupplier)
                      const _CategoryBadge(
                        label: 'Lieferant',
                        color: AppColors.privateOrange,
                        bg: AppColors.privateOrangeBg,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wiederverwendete Kartenoptik für Adresse/Kontaktdaten/Zahlungsangaben/
/// Notiz: weiss, sichtbarer Rahmen, abgerundet, dezenter Schatten, Icon plus
/// Titel.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.sky600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    this.showIcon = true,
  });

  final IconData icon;
  final String text;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 16, color: AppColors.sky600),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
