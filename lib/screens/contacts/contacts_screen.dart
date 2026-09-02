import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/max_width_box.dart';
import 'contact_detail_screen.dart';
import 'contact_editor_screen.dart';
import 'widgets/contact_list_tile.dart';

enum ContactsFilter { all, customers, suppliers }

/// „Kontakte“-Tab: Suche, Filter (Alle/Kunden/Lieferanten), Kontaktliste,
/// hochwertiger Leerzustand sowie Zugriff auf Detail-/Bearbeitungsansicht.
/// Die eigentliche Speicherung (inkl. Trennung von Demo- und echten Daten)
/// erfolgt ausschliesslich über die von `RootShell` übergebenen Callbacks –
/// dieser Screen hält selbst keinen dauerhaften Zustand.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({
    super.key,
    required this.contacts,
    required this.postalCodeService,
    required this.isContactInUse,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onCreateInvoice,
    required this.onCreateAppointment,
  });

  final List<Contact> contacts;
  final PostalCodeService postalCodeService;

  /// Ob [Contact] bereits von mindestens einer Rechnung oder einem Termin
  /// verwendet wird – entscheidet, ob Löschen archiviert statt entfernt.
  final bool Function(Contact) isContactInUse;

  final ValueChanged<Contact> onAdd;
  final ValueChanged<Contact> onUpdate;
  final ValueChanged<Contact> onDelete;

  /// Öffnet den Rechnungseditor, vorausgefüllt mit dem gewählten Kontakt
  /// (Schnellaktion auf der Detailseite).
  final ValueChanged<Contact> onCreateInvoice;

  /// Öffnet den Termin-Dialog, vorverknüpft mit dem gewählten Kontakt
  /// (Schnellaktion auf der Detailseite).
  final ValueChanged<Contact> onCreateAppointment;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  ContactsFilter _filter = ContactsFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> get _filtered {
    Iterable<Contact> list = widget.contacts;
    switch (_filter) {
      case ContactsFilter.all:
        break;
      case ContactsFilter.customers:
        list = list.where((c) => c.isCustomer);
      case ContactsFilter.suppliers:
        list = list.where((c) => c.isSupplier);
    }
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        return c.companyName.toLowerCase().contains(query) ||
            c.firstName.toLowerCase().contains(query) ||
            c.lastName.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.city.toLowerCase().contains(query) ||
            c.postalCode.toLowerCase().contains(query);
      });
    }
    // Neueste zuerst ist ohne Zeitstempel nicht sinnvoll – alphabetisch nach
    // Anzeigename ist für eine Kontaktliste am nachvollziehbarsten.
    final result = list.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return result;
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) =>
            ContactEditorScreen(postalCodeService: widget.postalCodeService),
      ),
    );
    if (result != null) widget.onAdd(result);
  }

  Future<void> _openDetail(Contact contact) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(
          contact: contact,
          postalCodeService: widget.postalCodeService,
          isContactInUse: widget.isContactInUse(contact),
          onUpdate: widget.onUpdate,
          onDelete: widget.onDelete,
          onCreateInvoice: widget.onCreateInvoice,
          onCreateAppointment: widget.onCreateAppointment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      body: SafeArea(
        child: MaxWidthBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Kontakte',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FittedBox statt eines festen Layouts, damit der Button
                    // auf sehr schmalen Bildschirmen (ab 320px) neben dem
                    // Titel Platz findet, ohne den Text abzuschneiden oder
                    // die Zeile zum Überlaufen zu bringen.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          key: const Key('contacts_add_button'),
                          onPressed: _openAdd,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Kontakt hinzufügen'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  key: const Key('contacts_search_field'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Suchen',
                    hintText: 'Firma, Name, E-Mail, PLZ, Ort …',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  // Reagiert direkt beim Schreiben – setState betrifft nur
                  // diesen Screen, nicht die übrige App.
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(ContactsFilter.all, 'Alle'),
                      _filterChip(ContactsFilter.customers, 'Kunden'),
                      _filterChip(ContactsFilter.suppliers, 'Lieferanten'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: widget.contacts.isEmpty
                    ? _buildEmptyState()
                    : (filtered.isEmpty
                          ? _buildFilterEmptyState()
                          : ListView.separated(
                              key: const Key('contacts_list'),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                100,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) => ContactListTile(
                                contact: filtered[index],
                                onTap: () => _openDetail(filtered[index]),
                              ),
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(ContactsFilter filter, String label) {
    final selected = _filter == filter;
    return ChoiceChip(
      key: Key('contacts_filter_${filter.name}'),
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
              'Keine Kontakte für diese Suche/diesen Filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _filter = ContactsFilter.all;
                _query = '';
                _searchController.clear();
              }),
              child: const Text('Alle anzeigen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const Key('contacts_empty_state'),
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
                Icons.people_alt_outlined,
                color: AppColors.sky600,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Noch keine Kontakte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Erstelle Kunden und Lieferanten, um sie später bei '
              'Rechnungen und Terminen wiederzuverwenden.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('contacts_empty_add_button'),
              onPressed: _openAdd,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Kontakt hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
