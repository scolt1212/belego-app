import 'package:flutter/material.dart';

import '../../../models/company_profile.dart';
import '../../../models/contact.dart';
import '../../../models/invoice_draft.dart';
import '../../../models/invoice_line_item.dart';
import '../../../services/postal_code_service.dart';
import '../../../widgets/max_width_box.dart';
import 'invoice_preview_screen.dart';
import 'widgets/invoice_customer_section.dart';
import 'widgets/invoice_details_section.dart';
import 'widgets/invoice_line_item_row.dart';
import 'widgets/invoice_line_items_section.dart';
import 'widgets/invoice_totals_summary.dart';

/// Erster echter Rechnungseditor. Erstellt oder bearbeitet einen
/// Rechnungsentwurf; die Daten leben vorerst nur im lokalen App-Zustand
/// (siehe ROADMAP.md für dauerhafte Speicherung).
class InvoiceEditorScreen extends StatefulWidget {
  const InvoiceEditorScreen({
    super.key,
    required this.companyProfile,
    required this.postalCodeService,
    required this.allocateInvoiceNumber,
    required this.onSaveDraft,
    this.existingDraft,
    this.contacts = const [],
    this.initialContact,
  });

  final CompanyProfile companyProfile;
  final PostalCodeService postalCodeService;

  /// Vergibt beim ersten Speichern die nächste feste Rechnungsnummer.
  final String Function() allocateInvoiceNumber;

  final ValueChanged<InvoiceDraft> onSaveDraft;

  /// Zum Bearbeiten eines bereits gespeicherten Entwurfs.
  final InvoiceDraft? existingDraft;

  /// Als Kunde auswählbare, bereits gespeicherte Kontakte (reine
  /// Lieferanten und archivierte Kontakte sind hier bereits ausgeschlossen,
  /// siehe `RootShell._selectableInvoiceCustomers`).
  final List<Contact> contacts;

  /// Kunde, mit dem eine NEUE Rechnung sofort vorausgefüllt geöffnet wird
  /// (z.B. „Rechnung erstellen“ auf der Kontakt-Detailseite). Wird bei
  /// [existingDraft] ignoriert und verändert weder Positionen, MWST,
  /// Zahlungsfrist noch Rechnungsnummer.
  final Contact? initialContact;

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late final InvoiceDraft _draft;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  bool _isDirty = false;

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerFirstNameController;
  late final TextEditingController _customerLastNameController;
  late final TextEditingController _customerStreetController;
  late final TextEditingController _customerHouseNumberController;
  late final TextEditingController _customerPostalCodeController;
  late final TextEditingController _customerCityController;
  late final TextEditingController _customerEmailController;
  late String _customerCountry;

  late final TextEditingController _paymentTermController;
  late final TextEditingController _titleController;
  late final TextEditingController _introTextController;

  late final List<LineItemControllers> _itemControllers;

  bool get _isEditingExisting => widget.existingDraft != null;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.existingDraft ??
        InvoiceDraft(
          invoiceDate: DateTime.now(),
          paymentTermDays: widget.companyProfile.paymentTermDays,
        );

    if (widget.existingDraft == null && _draft.items.length == 1) {
      // Neue Rechnung: erste Position übernimmt den Standard-MWST-Satz der
      // Firma (0.0 %, solange nicht MWST-pflichtig).
      _draft.items[0].vatRate = widget.companyProfile.isVatLiable
          ? widget.companyProfile.vatRate
          : 0.0;
    }

    final customer = _draft.customer;
    // Bei einer neuen Rechnung mit vorausgewähltem Kontakt (siehe
    // `initialContact`) werden die Kontroller direkt mit dessen Angaben statt
    // mit dem leeren `InvoiceCustomer` befüllt. Das geschieht bewusst schon
    // hier bei der Konstruktion (statt per `.text =` danach) – so lösen die
    // erst danach angehängten Dirty-Listener (`_dirty`) keinen `setState`
    // während `initState` aus, und ein nur vorausgefülltes, noch nicht vom
    // Nutzer verändertes Formular gilt zurecht nicht als „dirty“.
    final prefillContact = widget.existingDraft == null
        ? widget.initialContact
        : null;
    if (prefillContact != null) {
      _draft.customer.contactId = prefillContact.id;
    }
    _customerNameController = _dirty(
      TextEditingController(
        text: prefillContact != null
            ? (prefillContact.isCompany ? prefillContact.companyName : '')
            : customer.companyOrName,
      ),
    );
    _customerFirstNameController = _dirty(
      TextEditingController(
        text: prefillContact != null
            ? (prefillContact.isCompany ? '' : prefillContact.firstName)
            : customer.firstName,
      ),
    );
    _customerLastNameController = _dirty(
      TextEditingController(
        text: prefillContact != null
            ? (prefillContact.isCompany ? '' : prefillContact.lastName)
            : customer.lastName,
      ),
    );
    _customerStreetController = _dirty(
      TextEditingController(text: prefillContact?.street ?? customer.street),
    );
    _customerHouseNumberController = _dirty(
      TextEditingController(
        text: prefillContact?.houseNumber ?? customer.houseNumber,
      ),
    );
    _customerPostalCodeController = _dirty(
      TextEditingController(
        text: prefillContact?.postalCode ?? customer.postalCode,
      ),
    );
    _customerCityController = _dirty(
      TextEditingController(text: prefillContact?.city ?? customer.city),
    );
    _customerEmailController = _dirty(
      TextEditingController(text: prefillContact?.email ?? customer.email),
    );
    _customerCountry =
        (prefillContact != null && prefillContact.country.isNotEmpty)
        ? prefillContact.country
        : customer.country;

    _paymentTermController = _dirty(
      TextEditingController(text: '${_draft.paymentTermDays}'),
    );
    // Aktualisiert das automatisch berechnete Fälligkeitsdatum sofort.
    _paymentTermController.addListener(_handlePaymentTermChanged);
    _titleController = _dirty(TextEditingController(text: _draft.title));
    _introTextController = _dirty(
      TextEditingController(text: _draft.introText),
    );

    _itemControllers = [
      for (final item in _draft.items) LineItemControllers(item),
    ];
    for (final controllers in _itemControllers) {
      _dirty(controllers.descriptionController);
      _dirty(controllers.detailController);
      _dirty(controllers.quantityController);
      _dirty(controllers.unitPriceController);
    }
  }

  /// Registriert einen Dirty-Listener auf dem Controller und gibt ihn
  /// unverändert zurück (Komfort-Helfer für `initState`).
  TextEditingController _dirty(TextEditingController controller) {
    controller.addListener(_markDirty);
    return controller;
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _handlePaymentTermChanged() {
    final parsed = int.tryParse(_paymentTermController.text.trim());
    if (parsed != null && parsed > 0) {
      setState(() => _draft.paymentTermDays = parsed);
    }
  }

  /// Übernimmt Firma/Name, Adresse und E-Mail eines gewählten Kontakts in
  /// die Formularfelder (weiterhin frei editierbar) und merkt sich dessen
  /// stabile ID rein informativ auf dem Entwurf. Verändert bewusst keine
  /// Positionen, Preise, MWST, Zahlungsfrist oder Rechnungsnummer.
  void _handleContactSelected(Contact contact) {
    _customerNameController.text = contact.isCompany ? contact.companyName : '';
    _customerFirstNameController.text = contact.isCompany
        ? ''
        : contact.firstName;
    _customerLastNameController.text = contact.isCompany
        ? ''
        : contact.lastName;
    _customerStreetController.text = contact.street;
    _customerHouseNumberController.text = contact.houseNumber;
    _customerPostalCodeController.text = contact.postalCode;
    _customerCityController.text = contact.city;
    _customerEmailController.text = contact.email;
    _draft.customer.contactId = contact.id;
    setState(() {
      if (contact.country.isNotEmpty) _customerCountry = contact.country;
      _isDirty = true;
    });
  }

  void _saveCustomer() {
    _draft.customer
      ..companyOrName = _customerNameController.text.trim()
      ..firstName = _customerFirstNameController.text.trim()
      ..lastName = _customerLastNameController.text.trim()
      ..country = _customerCountry
      ..street = _customerStreetController.text.trim()
      ..houseNumber = _customerHouseNumberController.text.trim()
      ..postalCode = _customerPostalCodeController.text.trim()
      ..city = _customerCityController.text.trim()
      ..email = _customerEmailController.text.trim();
  }

  void _saveInvoiceMeta() {
    _draft
      ..paymentTermDays =
          int.tryParse(_paymentTermController.text.trim()) ??
          _draft.paymentTermDays
      ..title = _titleController.text.trim()
      ..introText = _introTextController.text.trim();
  }

  void _addItem() {
    setState(() {
      final item = InvoiceLineItem(
        vatRate: widget.companyProfile.isVatLiable
            ? widget.companyProfile.vatRate
            : 0.0,
      );
      _draft.items.add(item);
      _itemControllers.add(LineItemControllers(item));
      final added = _itemControllers.last;
      _dirty(added.descriptionController);
      _dirty(added.detailController);
      _dirty(added.quantityController);
      _dirty(added.unitPriceController);
      _isDirty = true;
    });
  }

  void _removeItem(int index) {
    if (_draft.items.length <= 1) return;
    setState(() {
      _draft.items.removeAt(index);
      _itemControllers.removeAt(index).dispose();
      _isDirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entwurf verwerfen?'),
        content: const Text('Möchtest du den Entwurf wirklich verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handlePopAttempt(bool didPop, Object? result) async {
    if (didPop) return;
    final shouldDiscard = await _confirmDiscard();
    if (shouldDiscard && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Prüft das gesamte Formular. Bei Fehlern werden sie an den Feldern
  /// angezeigt, eine verständliche Meldung erscheint und es wird zum Anfang
  /// des Formulars gescrollt, wo die meisten Pflichtfelder liegen.
  bool _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte die markierten Felder korrigieren.'),
        ),
      );
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    return isValid;
  }

  void _openPreview() {
    if (!_validateForm()) return;
    _saveCustomer();
    _saveInvoiceMeta();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          draft: _draft,
          companyProfile: widget.companyProfile,
        ),
      ),
    );
  }

  void _saveDraft() {
    if (!_validateForm()) return;
    _saveCustomer();
    _saveInvoiceMeta();
    // Die Nummer wird nur beim allerersten erfolgreichen Speichern vergeben
    // und bleibt danach für diesen Entwurf unverändert.
    _draft.invoiceNumber ??= widget.allocateInvoiceNumber();
    widget.onSaveDraft(_draft);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerStreetController.dispose();
    _customerHouseNumberController.dispose();
    _customerPostalCodeController.dispose();
    _customerCityController.dispose();
    _customerEmailController.dispose();
    _paymentTermController.dispose();
    _titleController.dispose();
    _introTextController.dispose();
    for (final controllers in _itemControllers) {
      controllers.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyIsVatLiable = widget.companyProfile.isVatLiable;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePopAttempt,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditingExisting ? 'Rechnung bearbeiten' : 'Rechnung erstellen',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: MaxWidthBox(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InvoiceCustomerSection(
                      formKey: _formKey,
                      companyOrNameController: _customerNameController,
                      firstNameController: _customerFirstNameController,
                      lastNameController: _customerLastNameController,
                      country: _customerCountry,
                      onCountryChanged: (value) => setState(() {
                        _customerCountry = value;
                        _isDirty = true;
                      }),
                      streetController: _customerStreetController,
                      houseNumberController: _customerHouseNumberController,
                      postalCodeController: _customerPostalCodeController,
                      cityController: _customerCityController,
                      postalCodeService: widget.postalCodeService,
                      emailController: _customerEmailController,
                      contacts: widget.contacts,
                      onContactSelected: _handleContactSelected,
                    ),
                    const SizedBox(height: 28),
                    InvoiceDetailsSection(
                      invoiceNumber: _draft.invoiceNumber,
                      invoiceDate: _draft.invoiceDate,
                      onInvoiceDateChanged: (date) => setState(() {
                        _draft.invoiceDate = date;
                        _isDirty = true;
                      }),
                      paymentTermController: _paymentTermController,
                      dueDate: _draft.dueDate,
                      titleController: _titleController,
                      introTextController: _introTextController,
                    ),
                    const SizedBox(height: 28),
                    InvoiceLineItemsSection(
                      items: _draft.items,
                      controllers: _itemControllers,
                      companyIsVatLiable: companyIsVatLiable,
                      onItemChanged: () => setState(() {}),
                      onAddItem: _addItem,
                      onRemoveItem: _removeItem,
                    ),
                    const SizedBox(height: 20),
                    InvoiceTotalsSummary(
                      draft: _draft,
                      companyIsVatLiable: companyIsVatLiable,
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton(
                      key: const Key('invoice_preview_button'),
                      onPressed: _openPreview,
                      child: const Text('Vorschau'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      key: const Key('invoice_save_draft_button'),
                      onPressed: _saveDraft,
                      child: const Text('Als Entwurf speichern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
