import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/iban.dart';
import '../../utils/swiss_phone_number.dart';
import '../../utils/validators.dart';
import '../../widgets/max_width_box.dart';
import '../../widgets/structured_address_fields.dart';

const TextStyle _sectionHeaderStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

/// Erstellt oder bearbeitet einen Kontakt. Ohne [existing] wird ein neuer
/// Kontakt angelegt (eine neue stabile ID wird erst beim Speichern vergeben);
/// mit [existing] bleibt dessen ID beim Bearbeiten unverändert.
class ContactEditorScreen extends StatefulWidget {
  const ContactEditorScreen({
    super.key,
    required this.postalCodeService,
    this.existing,
  });

  final PostalCodeService postalCodeService;
  final Contact? existing;

  @override
  State<ContactEditorScreen> createState() => _ContactEditorScreenState();
}

class _ContactEditorScreenState extends State<ContactEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late bool _isCompany;
  late bool _isCustomer;
  late bool _isSupplier;

  late final TextEditingController _companyNameController;
  late final TextEditingController _salutationController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late String _country;
  late final TextEditingController _streetController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ibanController;
  late final TextEditingController _noteController;

  bool get _isEditingExisting => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _isCompany = existing?.isCompany ?? true;
    _isCustomer = existing?.isCustomer ?? true;
    _isSupplier = existing?.isSupplier ?? false;
    _companyNameController = TextEditingController(
      text: existing?.companyName ?? '',
    );
    _salutationController = TextEditingController(
      text: existing?.salutation ?? '',
    );
    _firstNameController = TextEditingController(
      text: existing?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: existing?.lastName ?? '');
    _country = existing?.country ?? 'Schweiz';
    _streetController = TextEditingController(text: existing?.street ?? '');
    _houseNumberController = TextEditingController(
      text: existing?.houseNumber ?? '',
    );
    _postalCodeController = TextEditingController(
      text: existing?.postalCode ?? '',
    );
    _cityController = TextEditingController(text: existing?.city ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _phoneController = TextEditingController(
      text: existing != null
          ? SwissPhoneNumber.formatForDisplay(existing.phone)
          : '',
    );
    _ibanController = TextEditingController(
      text: existing != null && existing.iban.isNotEmpty
          ? Iban.formatForDisplay(existing.iban)
          : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _salutationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ibanController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _addressRequired => _isCustomer;

  void _submit() {
    if (!_formKey.currentState!.validate()) {
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
      return;
    }

    final isSwitzerland = _country == 'Schweiz';
    final rawPhone = _phoneController.text.trim();
    final normalizedPhone = rawPhone.isEmpty
        ? ''
        : (isSwitzerland
              ? (SwissPhoneNumber.normalize(rawPhone) ?? rawPhone)
              : rawPhone);
    // Die IBAN bleibt erhalten, auch wenn das Feld gerade nicht sichtbar ist
    // (reiner Kunde ohne Lieferantenrolle) – der Controller behält seinen
    // zuletzt eingegebenen Wert unabhängig von der Sichtbarkeit, siehe
    // Abschnitt „Zahlungsangaben“ weiter unten.
    final rawIban = _ibanController.text.trim();
    final normalizedIban = rawIban.isEmpty ? '' : Iban.normalize(rawIban);

    final contact =
        widget.existing ?? Contact(isCompany: _isCompany, isCustomer: true);
    contact
      ..isCompany = _isCompany
      ..companyName = _companyNameController.text.trim()
      ..salutation = _salutationController.text.trim()
      ..firstName = _firstNameController.text.trim()
      ..lastName = _lastNameController.text.trim()
      ..country = _country
      ..street = _streetController.text.trim()
      ..houseNumber = _houseNumberController.text.trim()
      ..postalCode = _postalCodeController.text.trim()
      ..city = _cityController.text.trim()
      ..email = _emailController.text.trim()
      ..phone = normalizedPhone
      ..iban = normalizedIban
      ..note = _noteController.text.trim()
      ..isCustomer = _isCustomer
      ..isSupplier = _isSupplier;

    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditingExisting ? 'Kontakt bearbeiten' : 'Kontakt hinzufügen',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: MaxWidthBox(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Kontaktart
                  const Text('Kontaktart', style: _sectionHeaderStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        key: const Key('contact_type_customer'),
                        label: const Text('Kunde'),
                        selected: _isCustomer,
                        onSelected: (v) => setState(() => _isCustomer = v),
                        selectedColor: AppColors.sky100,
                        checkmarkColor: AppColors.sky600,
                        labelStyle: TextStyle(
                          color: _isCustomer
                              ? AppColors.sky600
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilterChip(
                        key: const Key('contact_type_supplier'),
                        label: const Text('Lieferant'),
                        selected: _isSupplier,
                        onSelected: (v) => setState(() => _isSupplier = v),
                        selectedColor: AppColors.privateOrangeBg,
                        checkmarkColor: AppColors.privateOrange,
                        labelStyle: TextStyle(
                          color: _isSupplier
                              ? AppColors.privateOrange
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // 2. Firma oder Privatperson
                  const SizedBox(height: 24),
                  const Text(
                    'Firma oder Privatperson',
                    style: _sectionHeaderStyle,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    key: const Key('contact_is_company_selector'),
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Firma'),
                        icon: Icon(Icons.apartment_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Privatperson'),
                        icon: Icon(Icons.person_outline, size: 16),
                      ),
                    ],
                    selected: {_isCompany},
                    onSelectionChanged: (selection) =>
                        setState(() => _isCompany = selection.first),
                  ),

                  // 3. Name bzw. Firmenangaben
                  const SizedBox(height: 24),
                  Text(
                    _isCompany ? 'Firmenangaben' : 'Name',
                    style: _sectionHeaderStyle,
                  ),
                  const SizedBox(height: 8),
                  if (_isCompany) ...[
                    TextFormField(
                      key: const Key('contact_company_name'),
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Firmenname *',
                      ),
                      validator: (v) => Validators.required(
                        v,
                        message: 'Bitte Firmenname eingeben',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ansprechperson (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('contact_first_name'),
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vorname',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('contact_last_name'),
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nachname',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextFormField(
                      key: const Key('contact_salutation'),
                      controller: _salutationController,
                      decoration: const InputDecoration(
                        labelText: 'Anrede (optional)',
                        hintText: 'z. B. Herr',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('contact_first_name'),
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vorname',
                            ),
                            validator: (_) => _validatePersonName(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('contact_last_name'),
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nachname',
                            ),
                            validator: (_) => _validatePersonName(),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // 4. Adresse
                  const SizedBox(height: 24),
                  Text(
                    _addressRequired ? 'Adresse' : 'Adresse (optional)',
                    style: _sectionHeaderStyle,
                  ),
                  const SizedBox(height: 8),
                  StructuredAddressFields(
                    formKey: _formKey,
                    countryKey: const Key('contact_country'),
                    country: _country,
                    onCountryChanged: (value) =>
                        setState(() => _country = value),
                    streetKey: const Key('contact_street'),
                    streetController: _streetController,
                    houseNumberKey: const Key('contact_house_number'),
                    houseNumberController: _houseNumberController,
                    postalCodeController: _postalCodeController,
                    cityController: _cityController,
                    postalCodeService: widget.postalCodeService,
                    addressRequired: _addressRequired,
                  ),

                  // 5. Kontaktangaben
                  const SizedBox(height: 24),
                  const Text('Kontaktangaben', style: _sectionHeaderStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('contact_email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail (optional)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.email(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('contact_phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefonnummer (optional)',
                      hintText: 'z. B. 076 298 12 12',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return Validators.phoneNumber(
                        v,
                        isSwitzerland: _country == 'Schweiz',
                      );
                    },
                  ),

                  // 6. Zahlungsangaben – eine IBAN ist bei einem reinen
                  // Kunden in aller Regel nicht nötig und wird deshalb nur
                  // bei einer Lieferantenrolle angezeigt (siehe Auftrag
                  // „Kontakte“, Abschnitt IBAN). Der Wert im Controller
                  // bleibt beim Ein-/Ausblenden unangetastet – ein bereits
                  // erfasster Wert geht beim Wechsel der Kontaktart also nie
                  // verloren, er wird nur vorübergehend nicht angezeigt.
                  if (_isSupplier) ...[
                    const SizedBox(height: 24),
                    const Text('Zahlungsangaben', style: _sectionHeaderStyle),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('contact_iban'),
                      controller: _ibanController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IBAN (optional)',
                        hintText: 'z. B. CH93 0076 2011 6238 5295 7',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.iban(v);
                      },
                    ),
                  ],

                  // 7. Notiz
                  const SizedBox(height: 24),
                  const Text('Notiz', style: _sectionHeaderStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('contact_note'),
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notiz (optional)',
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    key: const Key('contact_save_button'),
                    onPressed: _submit,
                    child: Text(
                      _isEditingExisting
                          ? 'Änderungen speichern'
                          : 'Kontakt speichern',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePersonName() {
    if (_firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty) {
      return null;
    }
    return 'Bitte Vorname oder Nachname eingeben';
  }
}
