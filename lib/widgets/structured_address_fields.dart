import 'package:flutter/material.dart';

import '../services/postal_code_service.dart';
import '../utils/validators.dart';
import 'swiss_address_fields.dart';

const List<String> countryOptions = [
  'Schweiz',
  'Deutschland',
  'Österreich',
  'Liechtenstein',
  'Andere',
];

/// Wiederverwendbarer, strukturierter Adressblock: Land, Strasse, Hausnummer
/// sowie PLZ/Ort mit Schweizer Autovervollständigung. Wird sowohl bei der
/// Firmeneinrichtung als auch beim Rechnungsempfänger verwendet.
class StructuredAddressFields extends StatelessWidget {
  const StructuredAddressFields({
    super.key,
    required this.formKey,
    required this.countryKey,
    required this.country,
    required this.onCountryChanged,
    required this.streetKey,
    required this.streetController,
    required this.houseNumberKey,
    required this.houseNumberController,
    required this.postalCodeController,
    required this.cityController,
    required this.postalCodeService,
    this.addressRequired = true,
  });

  final GlobalKey<FormState> formKey;
  final Key countryKey;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final Key streetKey;
  final TextEditingController streetController;
  final Key houseNumberKey;
  final TextEditingController houseNumberController;
  final TextEditingController postalCodeController;
  final TextEditingController cityController;
  final PostalCodeService postalCodeService;

  /// Ob Strasse, Hausnummer, PLZ und Ort ausgefüllt sein müssen.
  /// Standardmässig `true` (Firmeneinrichtung, Rechnungsempfänger). Bei
  /// `false` bleiben leere Felder gültig – z.B. für einen Kontakt, der nur
  /// Lieferant und kein rechnungsfähiger Kunde ist.
  final bool addressRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: countryKey,
          initialValue: country,
          decoration: const InputDecoration(labelText: 'Land'),
          items: [
            for (final option in countryOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) {
            if (value != null) onCountryChanged(value);
          },
        ),
        const SizedBox(height: 16),
        // PLZ/Ort zuerst: der Nutzer sucht/wählt die Ortschaft, bevor er
        // Strasse und Hausnummer einträgt.
        SwissAddressFields(
          formKey: formKey,
          postalCodeController: postalCodeController,
          cityController: cityController,
          postalCodeService: postalCodeService,
          enabled: country == 'Schweiz',
          addressRequired: addressRequired,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                key: streetKey,
                controller: streetController,
                decoration: const InputDecoration(labelText: 'Strasse'),
                validator: addressRequired
                    ? (v) => Validators.required(
                        v,
                        message: 'Bitte Strasse eingeben',
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                key: houseNumberKey,
                controller: houseNumberController,
                decoration: const InputDecoration(labelText: 'Nr.'),
                validator: addressRequired
                    ? (v) => Validators.required(v, message: 'Pflichtfeld')
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
