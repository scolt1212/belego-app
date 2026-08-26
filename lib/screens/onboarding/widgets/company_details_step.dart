import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/postal_code_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validators.dart';
import '../../../widgets/structured_address_fields.dart';

/// Schritt 1 der Firmeneinrichtung: Angaben zum Unternehmen.
class CompanyDetailsStep extends StatelessWidget {
  const CompanyDetailsStep({
    super.key,
    required this.formKey,
    required this.companyNameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.isEditingContactPerson,
    required this.onEditContactPerson,
    required this.country,
    required this.onCountryChanged,
    required this.streetController,
    required this.houseNumberController,
    required this.postalCodeController,
    required this.cityController,
    required this.postalCodeService,
    required this.phoneController,
    required this.businessEmailController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyNameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isEditingContactPerson;
  final VoidCallback onEditContactPerson;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController streetController;
  final TextEditingController houseNumberController;
  final TextEditingController postalCodeController;
  final TextEditingController cityController;
  final PostalCodeService postalCodeService;
  final TextEditingController phoneController;
  final TextEditingController businessEmailController;

  @override
  Widget build(BuildContext context) {
    final isSwitzerland = country == 'Schweiz';

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('setup_company_name'),
            controller: companyNameController,
            decoration: const InputDecoration(labelText: 'Firmenname'),
            validator: (v) =>
                Validators.required(v, message: 'Bitte Firmenname eingeben'),
          ),
          const SizedBox(height: 16),
          _ContactPersonField(
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            isEditing: isEditingContactPerson,
            onEdit: onEditContactPerson,
          ),
          const SizedBox(height: 16),
          StructuredAddressFields(
            formKey: formKey,
            countryKey: const Key('setup_country'),
            country: country,
            onCountryChanged: onCountryChanged,
            streetKey: const Key('setup_street'),
            streetController: streetController,
            houseNumberKey: const Key('setup_house_number'),
            houseNumberController: houseNumberController,
            postalCodeController: postalCodeController,
            cityController: cityController,
            postalCodeService: postalCodeService,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('setup_phone'),
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
            ],
            decoration: const InputDecoration(labelText: 'Telefonnummer'),
            validator: (v) =>
                Validators.phoneNumber(v, isSwitzerland: isSwitzerland),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('setup_business_email'),
            controller: businessEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Geschäfts-E-Mail'),
            validator: Validators.email,
          ),
        ],
      ),
    );
  }
}

class _ContactPersonField extends StatelessWidget {
  const _ContactPersonField({
    required this.firstNameController,
    required this.lastNameController,
    required this.isEditing,
    required this.onEdit,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isEditing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.sky50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sky100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: AppColors.sky600),
                SizedBox(width: 6),
                Text(
                  'Ansprechperson ändern',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sky600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('setup_first_name'),
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'Vorname'),
                    validator: (v) =>
                        Validators.required(v, message: 'Pflichtfeld'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('setup_last_name'),
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Nachname'),
                    validator: (v) =>
                        Validators.required(v, message: 'Pflichtfeld'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ansprechperson',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${firstNameController.text} ${lastNameController.text}',
                  key: const Key('contact_person_display'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('contact_person_edit_button'),
            onPressed: onEdit,
            child: const Text('Ändern'),
          ),
        ],
      ),
    );
  }
}
