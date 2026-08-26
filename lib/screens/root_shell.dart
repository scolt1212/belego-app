import 'package:flutter/material.dart';

import '../models/company_profile.dart';
import '../models/invoice_draft.dart';
import '../services/postal_code_service.dart';
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

  /// Laufende Nummer für neu vergebene Rechnungsnummern. Wird erst beim
  /// ersten Speichern eines Entwurfs erhöht, nicht schon beim Öffnen des
  /// Editors – so verbraucht ein geöffnetes und wieder verworfenes leeres
  /// Formular keine Nummer.
  int _nextInvoiceSequence = 1;

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.today_outlined),
      activeIcon: Icon(Icons.today),
      label: 'Heute',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.smart_toy_outlined),
      activeIcon: Icon(Icons.smart_toy),
      label: 'Assistent',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      activeIcon: Icon(Icons.description),
      label: 'Dokumente',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
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

  List<Widget> _buildScreens() => [
    TodayScreen(
      isDemoMode: widget.isDemoMode,
      onCreateInvoice: _createNewInvoice,
    ),
    const PlaceholderScreen(title: 'Assistent', icon: Icons.smart_toy_outlined),
    DocumentsScreen(
      drafts: _draftInvoices,
      companyIsVatLiable: _companyProfile.isVatLiable,
      onOpenDraft: _openDraft,
    ),
    const PlaceholderScreen(title: 'Kontakte', icon: Icons.people_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }
}
