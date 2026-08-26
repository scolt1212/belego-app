import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/company_profile.dart';
import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/swiss_phone_number.dart';
import '../../widgets/max_width_box.dart';
import '../root_shell.dart';
import 'widgets/company_details_step.dart';
import 'widgets/finance_step.dart';
import 'widgets/step_progress.dart';
import 'widgets/summary_step.dart';

const _stepTitles = ['Unternehmen', 'Finanzen', 'Abschluss'];

/// Firmeneinrichtung nach der Registrierung, in drei Schritten.
/// Die Angaben werden vorerst nur lokal im Arbeitsspeicher gehalten.
class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({
    super.key,
    required this.registeredFirstName,
    required this.registeredLastName,
    required this.registeredEmail,
    required this.postalCodeService,
  });

  /// Vorname/Nachname aus der Registrierung, vorbelegt als Ansprechperson.
  final String registeredFirstName;
  final String registeredLastName;

  /// E-Mail aus der Registrierung, vorbelegt als Geschäfts-E-Mail (änderbar).
  final String registeredEmail;

  /// Amtliche PLZ-/Ortssuche, einmal beim App-Start geladen.
  final PostalCodeService postalCodeService;

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  int _stepIndex = 0;
  final CompanyProfile _profile = CompanyProfile();

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _isEditingContactPerson = false;
  String _country = 'Schweiz';
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _businessEmailController;

  final _ibanController = TextEditingController();
  bool _isVatLiable = false;
  final _vatNumberController = TextEditingController();
  double _vatRate = 8.1;
  final _paymentTermController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.registeredFirstName,
    );
    _lastNameController = TextEditingController(
      text: widget.registeredLastName,
    );
    _businessEmailController = TextEditingController(
      text: widget.registeredEmail,
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _businessEmailController.dispose();
    _ibanController.dispose();
    _vatNumberController.dispose();
    _paymentTermController.dispose();
    super.dispose();
  }

  void _saveStep1() {
    final isSwitzerland = _country == 'Schweiz';
    final rawPhone = _phoneController.text.trim();
    final normalizedPhone = isSwitzerland
        ? SwissPhoneNumber.normalize(rawPhone)
        : null;

    _profile
      ..companyName = _companyNameController.text.trim()
      ..firstName = _firstNameController.text.trim()
      ..lastName = _lastNameController.text.trim()
      ..country = _country
      ..street = _streetController.text.trim()
      ..houseNumber = _houseNumberController.text.trim()
      ..postalCode = _postalCodeController.text.trim()
      ..city = _cityController.text.trim()
      // Schweizer Nummern werden einheitlich normalisiert gespeichert
      // (z.B. "+41767567568"); bei anderen Ländern bzw. ungültigem Format
      // wird die Eingabe unverändert übernommen.
      ..phoneNumber = normalizedPhone ?? rawPhone
      ..businessEmail = _businessEmailController.text.trim().toLowerCase();
  }

  void _saveStep2() {
    _profile
      ..iban = _ibanController.text.replaceAll(' ', '').trim().toUpperCase()
      ..isVatLiable = _isVatLiable
      ..vatNumber = _isVatLiable ? _vatNumberController.text.trim() : ''
      // Ohne MWST-Pflicht bleibt der Standardsatz 0.0 %, auch wenn zuvor
      // testweise ein anderer Satz ausgewählt war.
      ..vatRate = _isVatLiable ? _vatRate : 0.0
      ..paymentTermDays =
          int.tryParse(_paymentTermController.text.trim()) ?? 30;
  }

  void _handleLogoChanged(Uint8List? bytes, String? fileName) {
    setState(() {
      _profile.logoBytes = bytes;
      _profile.logoFileName = fileName;
    });
  }

  void _goToPreviousStepOrLeave() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToNextStep() {
    if (_stepIndex == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      _saveStep1();
      setState(() => _stepIndex = 1);
    } else if (_stepIndex == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
      _saveStep2();
      setState(() => _stepIndex = 2);
    }
  }

  void _finishSetup() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RootShell(
          isDemoMode: false,
          companyProfile: _profile,
          postalCodeService: widget.postalCodeService,
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildStepContent() {
    switch (_stepIndex) {
      case 0:
        return CompanyDetailsStep(
          formKey: _step1FormKey,
          companyNameController: _companyNameController,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          isEditingContactPerson: _isEditingContactPerson,
          onEditContactPerson: () =>
              setState(() => _isEditingContactPerson = true),
          country: _country,
          onCountryChanged: (value) => setState(() => _country = value),
          streetController: _streetController,
          houseNumberController: _houseNumberController,
          postalCodeController: _postalCodeController,
          cityController: _cityController,
          postalCodeService: widget.postalCodeService,
          phoneController: _phoneController,
          businessEmailController: _businessEmailController,
        );
      case 1:
        return FinanceStep(
          formKey: _step2FormKey,
          ibanController: _ibanController,
          isVatLiable: _isVatLiable,
          onVatLiableChanged: (value) => setState(() => _isVatLiable = value),
          vatNumberController: _vatNumberController,
          vatRate: _vatRate,
          onVatRateChanged: (value) => setState(() => _vatRate = value),
          paymentTermController: _paymentTermController,
        );
      default:
        // Zeigt die zuletzt gespeicherten Werte; beim Zurückgehen aus der
        // Zusammenfassung bleiben Schritt 1 und 2 unverändert erhalten.
        _saveStep1();
        _saveStep2();
        return SummaryStep(
          profile: _profile,
          onLogoChanged: _handleLogoChanged,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _stepIndex == _stepTitles.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma einrichten'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToPreviousStepOrLeave,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MaxWidthBox(
              child: StepProgress(currentStep: _stepIndex, titles: _stepTitles),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: MaxWidthBox(child: _buildStepContent()),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: MaxWidthBox(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('setup_primary_action'),
                    onPressed: isLastStep ? _finishSetup : _goToNextStep,
                    child: Text(isLastStep ? 'Belego starten' : 'Weiter'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
