import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/company_profile.dart';
import '../models/contact.dart';
import '../models/invoice_draft.dart';
import '../models/task_item.dart';
import '../services/postal_code_service.dart';
import '../theme/app_theme.dart';
import 'documents/documents_screen.dart';
import 'documents/invoice/invoice_editor_screen.dart';
import 'placeholder_screen.dart';
import 'today/today_screen.dart';

/// Hauptgerüst der App mit den 4 Tabs unten: Heute, Assistent, Dokumente, Kontakte.
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    this.isDemoMode = false,
    this.companyProfile,
    required this.postalCodeService,
  });

  /// Im Demo-Modus zeigt der „Heute“-Tab Beispieldaten statt des leeren
  /// Zustands für neu registrierte Benutzer.
  final bool isDemoMode;

  /// Firmenprofil aus der Firmeneinrichtung. Fehlt es (z.B. nach „Anmelden“
  /// ohne echtes Backend), wird ein leeres Standardprofil verwendet.
  final CompanyProfile? companyProfile;

  /// Amtliche PLZ-/Ortssuche, einmal beim App-Start geladen.
  final PostalCodeService postalCodeService;

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

  /// Noch keine echte Kontaktverwaltung (kein „Kontakt hinzufügen“ im UI) –
  /// diese Liste bleibt für echte Konten deshalb bewusst leer, siehe
  /// `Contact` und ROADMAP.md.
  final List<Contact> _contacts = [];
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

  void _createNewInvoice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          companyProfile: _companyProfile,
          postalCodeService: widget.postalCodeService,
          allocateInvoiceNumber: _allocateInvoiceNumber,
          onSaveDraft: _saveDraft,
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

  List<Widget> _buildScreens() => [
    TodayScreen(
      isDemoMode: widget.isDemoMode,
      companyProfile: _companyProfile,
      invoices: _draftInvoices,
      companyIsVatLiable: _companyProfile.isVatLiable,
      appointments: _appointments,
      tasks: _tasks,
      contacts: _contacts,
      onCreateInvoice: _createNewInvoice,
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
    const PlaceholderScreen(title: 'Kontakte', icon: Icons.people_outline),
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
