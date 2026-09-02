import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/company_profile.dart';
import '../models/contact.dart';
import '../models/invoice_draft.dart';
import '../models/task_item.dart';
import '../services/contact_repository.dart';
import '../services/postal_code_service.dart';
import '../theme/app_theme.dart';
import 'contacts/contact_editor_screen.dart';
import 'contacts/contacts_screen.dart';
import 'documents/documents_screen.dart';
import 'documents/invoice/invoice_editor_screen.dart';
import 'placeholder_screen.dart';
import 'today/today_screen.dart';
import 'today/widgets/appointment_editor_dialog.dart';

/// Hauptgerüst der App mit den 4 Tabs unten: Heute, Assistent, Dokumente, Kontakte.
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    this.isDemoMode = false,
    this.companyProfile,
    required this.postalCodeService,
    required this.contactRepository,
  });

  /// Im Demo-Modus zeigt der „Heute“-Tab Beispieldaten statt des leeren
  /// Zustands für neu registrierte Benutzer.
  final bool isDemoMode;

  /// Firmenprofil aus der Firmeneinrichtung. Fehlt es (z.B. nach „Anmelden“
  /// ohne echtes Backend), wird ein leeres Standardprofil verwendet.
  final CompanyProfile? companyProfile;

  /// Amtliche PLZ-/Ortssuche, einmal beim App-Start geladen.
  final PostalCodeService postalCodeService;

  /// Dauerhafte lokale Speicherung der echten (Nicht-Demo-) Kontakte.
  final ContactRepository contactRepository;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;
  late final CompanyProfile _companyProfile =
      widget.companyProfile ?? CompanyProfile();
  final List<InvoiceDraft> _draftInvoices = [];
  final List<Appointment> _appointments = [];
  final List<TaskItem> _tasks = [];

  /// Echte, dauerhaft gespeicherte Kontakte (siehe `ContactRepository`).
  /// Einmalig beim Start dieses `RootShell` aus dem lokalen Speicher
  /// geladen; jede Änderung wird sofort zurückgeschrieben.
  late List<Contact> _contacts = widget.contactRepository.readAll();

  /// Ausschliesslich für den Demo-Modus im Kontakte-Tab: unabhängige,
  /// rein lokale Beispieldaten, die NIE dauerhaft gespeichert werden und nie
  /// mit [_contacts] vermischt werden (siehe ROADMAP.md). Getrennt von den
  /// Beispieldaten auf „Heute“ (dort privat in `TodayScreenState`).
  late List<Contact> _demoContacts = _buildDemoContacts();

  DocumentsFilter _documentsFilter = DocumentsFilter.all;

  /// Laufende Nummer für neu vergebene Rechnungsnummern. Wird erst beim
  /// ersten Speichern eines Entwurfs erhöht, nicht schon beim Öffnen des
  /// Editors – so verbraucht ein geöffnetes und wieder verworfenes leeres
  /// Formular keine Nummer.
  int _nextInvoiceSequence = 1;

  static const List<NavigationDestination> _navItems = [
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Heute',
    ),
    NavigationDestination(
      icon: Icon(Icons.smart_toy_outlined),
      selectedIcon: Icon(Icons.smart_toy),
      label: 'Assistent',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Dokumente',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Kontakte',
    ),
  ];

  String _allocateInvoiceNumber() {
    final year = DateTime.now().year;
    final number =
        'RE-$year-${_nextInvoiceSequence.toString().padLeft(4, '0')}';
    _nextInvoiceSequence += 1;
    return number;
  }

  void _saveDraft(InvoiceDraft draft) {
    setState(() {
      final index = _draftInvoices.indexWhere(
        (d) => d.invoiceNumber == draft.invoiceNumber,
      );
      if (index >= 0) {
        _draftInvoices[index] = draft;
      } else {
        _draftInvoices.add(draft);
      }
      _selectedIndex = 2; // Dokumente
    });
  }

  /// Kontakte, die im Rechnungseditor als Kunde auswählbar sind: reine
  /// Lieferanten erscheinen dort bewusst nicht (ausser sie sind gleichzeitig
  /// als Kunde markiert), archivierte Kontakte ebenfalls nicht – siehe
  /// Auftrag „Kontakte“.
  List<Contact> get _selectableInvoiceCustomers =>
      _contacts.where((c) => c.isCustomer && !c.isArchived).toList();

  void _createNewInvoice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          companyProfile: _companyProfile,
          postalCodeService: widget.postalCodeService,
          allocateInvoiceNumber: _allocateInvoiceNumber,
          onSaveDraft: _saveDraft,
          contacts: _selectableInvoiceCustomers,
        ),
      ),
    );
  }

  void _openDraft(InvoiceDraft draft) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          companyProfile: _companyProfile,
          postalCodeService: widget.postalCodeService,
          allocateInvoiceNumber: _allocateInvoiceNumber,
          existingDraft: draft,
          onSaveDraft: _saveDraft,
          contacts: _selectableInvoiceCustomers,
        ),
      ),
    );
  }

  /// Öffnet einen neuen Rechnungsentwurf, vorausgefüllt mit [contact] (siehe
  /// „Rechnung erstellen“ auf der Kontakt-Detailseite) – nutzt dieselbe
  /// Übernahmelogik wie die Kontaktsuche im Rechnungseditor
  /// (`InvoiceEditorScreen.initialContact`), verändert also weder
  /// Positionen, MWST, Zahlungsfrist noch Rechnungsnummer.
  void _createInvoiceForContact(Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          companyProfile: _companyProfile,
          postalCodeService: widget.postalCodeService,
          allocateInvoiceNumber: _allocateInvoiceNumber,
          onSaveDraft: _saveDraft,
          contacts: _selectableInvoiceCustomers,
          initialContact: contact,
        ),
      ),
    );
  }

  /// Ändert den fachlichen Status einer Rechnung. „Als bezahlt markieren“
  /// setzt zusätzlich `paidAt` auf jetzt (massgeblich für den Umsatz des
  /// Monats); jeder andere Statuswechsel löscht `paidAt` wieder, damit keine
  /// veraltete Zahlungsinformation stehen bleibt.
  void _updateInvoiceStatus(InvoiceDraft draft, InvoiceStatus status) {
    setState(() {
      draft.status = status;
      draft.paidAt = status == InvoiceStatus.paid ? DateTime.now() : null;
    });
  }

  void _openDocumentsWithFilter(DocumentsFilter filter) {
    setState(() {
      _documentsFilter = filter;
      _selectedIndex = 2;
    });
  }

  void _addAppointment(Appointment appointment) {
    setState(() => _appointments.add(appointment));
  }

  void _updateAppointment(Appointment appointment) {
    setState(() {
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index >= 0) _appointments[index] = appointment;
    });
  }

  void _deleteAppointment(String id) {
    setState(() => _appointments.removeWhere((a) => a.id == id));
  }

  void _addTask(TaskItem task) {
    setState(() => _tasks.add(task));
  }

  void _toggleTask(String id) {
    setState(() {
      for (final task in _tasks) {
        if (task.id == id) task.isDone = !task.isDone;
      }
    });
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((task) => task.id == id));
  }

  // --- Kontakte -------------------------------------------------------

  /// Öffnet denselben Kontakteditor wie „Kontakt hinzufügen“ im
  /// Kontakte-Tab – aufgerufen von der Schnellaktion „Kontakt hinzufügen“
  /// auf „Heute“. Kein zweiter Editor, keine eigene Speicherlogik: ein
  /// erfolgreich gespeicherter Kontakt läuft über [_addContact] und ist
  /// danach sofort im Kontakte-Tab sichtbar; bei Abbruch (`pop(null)`)
  /// entsteht kein Kontakt.
  Future<void> _openContactEditorFromToday() async {
    final result = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) =>
            ContactEditorScreen(postalCodeService: widget.postalCodeService),
      ),
    );
    if (result != null) _addContact(result);
  }

  /// Öffnet den bestehenden Termin-Dialog, vorverknüpft mit [contact] (siehe
  /// „Termin erstellen“ auf der Kontakt-Detailseite). Der Termintitel bleibt
  /// dabei leer/manuell – die Kontaktverknüpfung überschreibt ihn nicht
  /// (siehe `AppointmentEditorDialog`).
  Future<void> _createAppointmentForContact(Contact contact) async {
    final result = await showAppointmentEditorDialog(
      context,
      initialDate: DateTime.now(),
      contacts: widget.isDemoMode ? _demoContacts : _contacts,
      initialContact: contact,
    );
    if (result == null) return;
    // Im Demo-Modus bewusst nicht übernommen: Demo-Termine leben unabhängig
    // und privat in `TodayScreenState._demoAppointments` (siehe dort) – das
    // hier nachzubilden würde die „Heute“-Seite verändern, was dieser
    // Auftrag ausdrücklich nicht vorsieht. Für echte Konten funktioniert die
    // Verknüpfung vollständig.
    if (!widget.isDemoMode) _addAppointment(result);
  }

  /// Rein lokale, klar als Beispiel erkennbare Kontakte für den Kontakte-Tab
  /// im Demo-Modus – werden nie gespeichert und nie mit [_contacts]
  /// vermischt (siehe Klassendokumentation).
  List<Contact> _buildDemoContacts() => [
    Contact(
      isCompany: true,
      companyName: 'Sonnenhof Gartenbau AG',
      street: 'Gartenweg',
      houseNumber: '12',
      postalCode: '8400',
      city: 'Winterthur',
      email: 'info@sonnenhof-beispiel.example',
      phone: '+41521234567',
      isCustomer: true,
    ),
    Contact(
      isCompany: false,
      salutation: 'Frau',
      firstName: 'Laura',
      lastName: 'Fischer',
      street: 'Seestrasse',
      houseNumber: '3',
      postalCode: '8800',
      city: 'Thalwil',
      phone: '+41791234567',
      isCustomer: true,
    ),
    Contact(
      isCompany: true,
      companyName: 'Baumaterial Keller GmbH',
      street: 'Industriestrasse',
      houseNumber: '7',
      postalCode: '8500',
      city: 'Frauenfeld',
      email: 'bestellungen@keller-beispiel.example',
      isCustomer: false,
      isSupplier: true,
    ),
    Contact(
      isCompany: true,
      companyName: 'Muster Treuhand & Beratung AG',
      street: 'Bahnhofplatz',
      houseNumber: '2',
      postalCode: '9000',
      city: 'St. Gallen',
      email: 'kontakt@muster-treuhand.example',
      isCustomer: true,
      isSupplier: true,
    ),
  ];

  /// Ob [contact] bereits von mindestens einer Rechnung oder einem Termin
  /// verwendet wird – entscheidet, ob Löschen stattdessen archiviert (siehe
  /// `ContactDetailScreen`). Rechnungen verweisen dabei nur über die zum
  /// Auswahlzeitpunkt kopierte `InvoiceCustomer.contactId`, nie über den
  /// (danach unabhängigen) Namen. `_draftInvoices`/`_appointments` enthalten
  /// – unabhängig vom Demo-Modus – ausschliesslich Verweise auf echte
  /// Kontakte (siehe `_selectableInvoiceCustomers` und den Termin-Dialog auf
  /// „Heute“); ein Demo-Kontakt kann hier also nie als „verwendet“ gelten.
  bool _isContactInUse(Contact contact) {
    final usedByInvoice = _draftInvoices.any(
      (d) => d.customer.contactId == contact.id,
    );
    final usedByAppointment = _appointments.any(
      (a) => a.contactId == contact.id,
    );
    return usedByInvoice || usedByAppointment;
  }

  void _addContact(Contact contact) {
    setState(() {
      if (widget.isDemoMode) {
        _demoContacts = [..._demoContacts, contact];
      } else {
        _contacts = [..._contacts, contact];
        widget.contactRepository.saveAll(_contacts);
      }
    });
  }

  void _updateContact(Contact updated) {
    setState(() {
      if (widget.isDemoMode) {
        _demoContacts = [
          for (final c in _demoContacts)
            if (c.id == updated.id) updated else c,
        ];
      } else {
        _contacts = [
          for (final c in _contacts)
            if (c.id == updated.id) updated else c,
        ];
        widget.contactRepository.saveAll(_contacts);
      }
    });
  }

  /// Löscht [contact] endgültig, falls er nirgends verwendet wird – sonst
  /// wird er stattdessen archiviert, damit bestehende Rechnungen/Termine
  /// nicht beschädigt werden (siehe `_isContactInUse`).
  void _deleteOrArchiveContact(Contact contact) {
    setState(() {
      final inUse = _isContactInUse(contact);
      if (inUse) contact.isArchived = true;
      if (widget.isDemoMode) {
        _demoContacts = inUse
            ? [
                for (final c in _demoContacts)
                  if (c.id == contact.id) contact else c,
              ]
            : _demoContacts.where((c) => c.id != contact.id).toList();
      } else {
        _contacts = inUse
            ? [
                for (final c in _contacts)
                  if (c.id == contact.id) contact else c,
              ]
            : _contacts.where((c) => c.id != contact.id).toList();
        widget.contactRepository.saveAll(_contacts);
      }
    });
  }

  List<Widget> _buildScreens() => [
    TodayScreen(
      isDemoMode: widget.isDemoMode,
      companyProfile: _companyProfile,
      invoices: _draftInvoices,
      companyIsVatLiable: _companyProfile.isVatLiable,
      appointments: _appointments,
      tasks: _tasks,
      // Dieselbe zentrale Kontaktquelle wie der „Kontakte“-Tab (siehe dort)
      // – „Heute“ pflegt keine eigene, separate Demo-Kontaktliste mehr, damit
      // ein neu erstellter Kontakt (Demo oder echt) sofort auch in der
      // Kontaktsuche des Termin-Dialogs auffindbar ist.
      contacts: widget.isDemoMode ? _demoContacts : _contacts,
      onCreateInvoice: _createNewInvoice,
      onAddContact: _openContactEditorFromToday,
      onOpenDocuments: _openDocumentsWithFilter,
      onLeaveDemo: () => Navigator.of(context).pop(),
      onAddAppointment: _addAppointment,
      onUpdateAppointment: _updateAppointment,
      onDeleteAppointment: _deleteAppointment,
      onAddTask: _addTask,
      onToggleTask: _toggleTask,
      onDeleteTask: _deleteTask,
    ),
    const PlaceholderScreen(title: 'Assistent', icon: Icons.smart_toy_outlined),
    DocumentsScreen(
      key: ValueKey(_documentsFilter),
      drafts: _draftInvoices,
      companyIsVatLiable: _companyProfile.isVatLiable,
      onOpenDraft: _openDraft,
      onChangeStatus: _updateInvoiceStatus,
      initialFilter: _documentsFilter,
    ),
    ContactsScreen(
      contacts: widget.isDemoMode ? _demoContacts : _contacts,
      postalCodeService: widget.postalCodeService,
      isContactInUse: _isContactInUse,
      onAdd: _addContact,
      onUpdate: _updateContact,
      onDelete: _deleteOrArchiveContact,
      onCreateInvoice: _createInvoiceForContact,
      onCreateAppointment: _createAppointmentForContact,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: _navItems,
          ),
        ),
      ),
    );
  }
}
