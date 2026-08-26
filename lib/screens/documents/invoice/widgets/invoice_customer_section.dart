import 'package:flutter/material.dart';

import '../../../../services/postal_code_service.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/structured_address_fields.dart';

/// Abschnitt „Kunde“ im Rechnungseditor: Rechnungsempfänger mit derselben
/// strukturierten Adresslogik wie die Firmenadresse. Ist Teil des
/// übergeordneten Formulars im Rechnungseditor (kein eigenes `Form`).
class InvoiceCustomerSection extends StatelessWidget {
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
        TextFormField(
          key: const Key('invoice_customer_name'),
          controller: companyOrNameController,
          decoration: const InputDecoration(labelText: 'Firma oder Name'),
          validator: (v) {
            final hasCompanyOrFullName =
                (v?.trim().isNotEmpty ?? false) ||
                (firstNameController.text.trim().isNotEmpty &&
                    lastNameController.text.trim().isNotEmpty);
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
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname (optional)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('invoice_customer_last_name'),
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nachname (optional)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StructuredAddressFields(
          formKey: formKey,
          countryKey: const Key('invoice_customer_country'),
          country: country,
          onCountryChanged: onCountryChanged,
          streetKey: const Key('invoice_customer_street'),
          streetController: streetController,
          houseNumberKey: const Key('invoice_customer_house_number'),
          houseNumberController: houseNumberController,
          postalCodeController: postalCodeController,
          cityController: cityController,
          postalCodeService: postalCodeService,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('invoice_customer_email'),
          controller: emailController,
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
