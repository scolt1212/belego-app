import 'package:flutter/material.dart';

import '../../../../models/contact.dart';
import '../../../../services/postal_code_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/structured_address_fields.dart';

/// Abschnitt „Kunde“ im Rechnungseditor: optionale Suche nach einem
/// gespeicherten Kontakt (nur Kunden, keine reinen Lieferanten, keine
/// archivierten Kontakte – das Filtern übernimmt bereits `RootShell`) plus
/// dieselbe strukturierte Adresslogik wie die Firmenadresse für die
/// weiterhin mögliche manuelle Eingabe. Ist Teil des übergeordneten
/// Formulars im Rechnungseditor (kein eigenes `Form`).
class InvoiceCustomerSection extends StatefulWidget {
  const InvoiceCustomerSection({
    super.key,
    required this.formKey,
    required this.companyOrNameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.country,
    required this.onCountryChanged,
    required this.streetController,
    required this.houseNumberController,
    required this.postalCodeController,
    required this.cityController,
    required this.postalCodeService,
    required this.emailController,
    this.contacts = const [],
    this.onContactSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyOrNameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController streetController;
  final TextEditingController houseNumberController;
  final TextEditingController postalCodeController;
  final TextEditingController cityController;
  final PostalCodeService postalCodeService;
  final TextEditingController emailController;

  /// Bereits als Kunde auswählbare, nicht archivierte Kontakte.
  final List<Contact> contacts;

  /// Wird aufgerufen, sobald ein Vorschlag angetippt wird – der
  /// Rechnungseditor übernimmt daraufhin dessen Angaben in die Felder unten.
  final ValueChanged<Contact>? onContactSelected;

  @override
  State<InvoiceCustomerSection> createState() => _InvoiceCustomerSectionState();
}

class _InvoiceCustomerSectionState extends State<InvoiceCustomerSection> {
  final _searchController = TextEditingController();
  List<Contact> _suggestions = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      _suggestions = trimmed.isEmpty
          ? const []
          : widget.contacts
                .where((c) => c.displayName.toLowerCase().contains(trimmed))
                .toList();
    });
  }

  void _selectContact(Contact contact) {
    _searchController.clear();
    setState(() => _suggestions = const []);
    FocusScope.of(context).unfocus();
    widget.onContactSelected?.call(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kunde',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (widget.contacts.isNotEmpty) ...[
          TextField(
            key: const Key('invoice_customer_search'),
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Gespeicherten Kunden suchen (optional)',
              suffixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: _handleSearchChanged,
          ),
          if (_suggestions.isNotEmpty)
            Container(
              key: const Key('invoice_customer_suggestions'),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _suggestions.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.fieldBorder),
                    Builder(
                      builder: (context) {
                        final contact = _suggestions[i];
                        return InkWell(
                          key: Key('invoice_customer_suggestion_${contact.id}'),
                          onTap: () => _selectContact(contact),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (contact.address.isNotEmpty)
                                  Text(
                                    contact.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          key: const Key('invoice_customer_name'),
          controller: widget.companyOrNameController,
          decoration: const InputDecoration(labelText: 'Firma oder Name'),
          validator: (v) {
            final hasCompanyOrFullName =
                (v?.trim().isNotEmpty ?? false) ||
                (widget.firstNameController.text.trim().isNotEmpty &&
                    widget.lastNameController.text.trim().isNotEmpty);
            return hasCompanyOrFullName
                ? null
                : 'Bitte Firma oder vollständigen Namen angeben';
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('invoice_customer_first_name'),
                controller: widget.firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname (optional)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('invoice_customer_last_name'),
                controller: widget.lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname (optional)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StructuredAddressFields(
          formKey: widget.formKey,
          countryKey: const Key('invoice_customer_country'),
          country: widget.country,
          onCountryChanged: widget.onCountryChanged,
          streetKey: const Key('invoice_customer_street'),
          streetController: widget.streetController,
          houseNumberKey: const Key('invoice_customer_house_number'),
          houseNumberController: widget.houseNumberController,
          postalCodeController: widget.postalCodeController,
          cityController: widget.cityController,
          postalCodeService: widget.postalCodeService,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('invoice_customer_email'),
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-Mail (optional)'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return Validators.email(v);
          },
        ),
      ],
    );
  }
}
