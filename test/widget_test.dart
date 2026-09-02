import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:belego/main.dart';
import 'package:belego/models/company_profile.dart';
import 'package:belego/models/contact.dart';
import 'package:belego/models/invoice_draft.dart';
import 'package:belego/screens/contacts/widgets/contact_list_tile.dart';
import 'package:belego/screens/documents/invoice/invoice_editor_screen.dart';
import 'package:belego/screens/onboarding/company_setup_screen.dart';
import 'package:belego/screens/onboarding/widgets/company_logo_section.dart';
import 'package:belego/screens/root_shell.dart';
import 'package:belego/services/contact_repository.dart';
import 'package:belego/services/postal_code_service.dart';
import 'package:belego/theme/app_theme.dart';
import 'package:belego/utils/iban.dart';
import 'package:belego/utils/logo_validation.dart';
import 'package:belego/utils/money.dart';
import 'package:belego/utils/swiss_phone_number.dart';
import 'package:belego/utils/swiss_vat_number.dart';
import 'package:belego/utils/validators.dart';

// Kleinstmögliches gültiges PNG (1×1, transparent) – eindeutig als
// Test-/Platzhalterbild erkennbar, keine echten Bilddaten.
final Uint8List _testPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

// Offizielle Beispiel-IBAN aus der ISO-13616-/SEPA-Dokumentation, keine
// echte Bankverbindung. Erfüllt absichtlich die Modulo-97-Prüfsumme.
const _validIban = 'CH93 0076 2011 6238 5295 7';
final _swissDateFormat = DateFormat('dd.MM.yyyy');

/// Der „Heute“-Screen ist lang (Kopfbereich, Finanzübersicht, Schnellaktionen,
/// Kalender, Aufgaben); im Standard-Testfenster (800x600 logisch) würde die
/// lazy gebaute äussere Liste Kalender/Aufgaben nicht materialisieren. Ein
/// grosszügig hohes Testfenster stellt sicher, dass die ganze Seite ohne
/// Scrollen sichtbar (und damit testbar) ist.
void useTallTestViewport(WidgetTester tester) {
  final originalPhysicalSize = tester.view.physicalSize;
  final originalDevicePixelRatio = tester.view.devicePixelRatio;
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalPhysicalSize;
    tester.view.devicePixelRatio = originalDevicePixelRatio;
  });
}

void main() {
  late PostalCodeService postalCodeService;
  late ContactRepository contactRepository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('de_CH');
    final entries = await PostalCodeService.loadEntriesFromAsset();
    postalCodeService = PostalCodeService(entries: entries);
  });

  // Frische, leere lokale Speicherung vor jedem einzelnen Test – Kontakte
  // aus einem Test dürfen nie in einen anderen durchsickern (siehe Test
  // „Kontakte bleiben nach einem simulierten Neustart erhalten“ für den
  // bewusst gegenteiligen Fall INNERHALB eines Tests).
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    contactRepository = await ContactRepository.load();
  });

  Widget wrapSetupScreen({
    String registeredFirstName = 'Anna',
    String registeredLastName = 'Muster',
    String registeredEmail = 'anna@muster-ag.ch',
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: CompanySetupScreen(
        registeredFirstName: registeredFirstName,
        registeredLastName: registeredLastName,
        registeredEmail: registeredEmail,
        postalCodeService: postalCodeService,
        contactRepository: contactRepository,
      ),
    );
  }

  /// Füllt Schritt 1 mit gültigen Minimalangaben und geht weiter zu Schritt 2.
  Future<void> completeStep1(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('setup_company_name')),
      'Muster AG',
    );
    await tester.enterText(
      find.byKey(const Key('setup_street')),
      'Bahnhofstrasse',
    );
    await tester.enterText(find.byKey(const Key('setup_house_number')), '1');
    await tester.enterText(find.byKey(const Key('setup_postal_code')), '8340');
    await tester.enterText(find.byKey(const Key('setup_city')), 'Hinwil');
    await tester.enterText(
      find.byKey(const Key('setup_phone')),
      '076 298 12 12',
    );
    await tester.tap(find.byKey(const Key('setup_primary_action')));
    await tester.pumpAndSettle();
  }

  CompanyProfile testCompanyProfile({
    bool isVatLiable = false,
    double vatRate = 8.1,
    int paymentTermDays = 30,
  }) {
    return CompanyProfile()
      ..companyName = 'Muster AG'
      ..firstName = 'Anna'
      ..lastName = 'Muster'
      ..street = 'Bahnhofstrasse'
      ..houseNumber = '1'
      ..postalCode = '8340'
      ..city = 'Hinwil'
      ..country = 'Schweiz'
      ..phoneNumber = '+41762981212'
      ..businessEmail = 'info@muster-ag.ch'
      ..iban = 'CH9300762011623852957'
      ..isVatLiable = isVatLiable
      ..vatRate = vatRate
      ..paymentTermDays = paymentTermDays;
  }

  Widget wrapRootShell({
    bool isDemoMode = false,
    CompanyProfile? companyProfile,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: RootShell(
        isDemoMode: isDemoMode,
        companyProfile: companyProfile ?? testCompanyProfile(),
        postalCodeService: postalCodeService,
        contactRepository: contactRepository,
      ),
    );
  }

  Widget wrapInvoiceEditor({
    required CompanyProfile companyProfile,
    InvoiceDraft? existingDraft,
    ValueChanged<InvoiceDraft>? onSaveDraft,
    String Function()? allocateInvoiceNumber,
    List<Contact> contacts = const [],
  }) {
    var sequence = 1;
    return MaterialApp(
      theme: AppTheme.light(),
      home: InvoiceEditorScreen(
        companyProfile: companyProfile,
        postalCodeService: postalCodeService,
        allocateInvoiceNumber:
            allocateInvoiceNumber ??
            () => 'RE-2026-${(sequence++).toString().padLeft(4, '0')}',
        existingDraft: existingDraft,
        onSaveDraft: onSaveDraft ?? (_) {},
        contacts: contacts,
      ),
    );
  }

  /// Bettet den Rechnungseditor MIT einer vorgelagerten Route ein, damit
  /// Zurück-Navigation (AppBar-Pfeil, PopScope) realistisch getestet werden
  /// kann.
  Widget invoiceEditorHost({
    required CompanyProfile companyProfile,
    ValueChanged<InvoiceDraft>? onSaveDraft,
  }) {
    var sequence = 1;
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open_invoice_editor'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceEditorScreen(
                    companyProfile: companyProfile,
                    postalCodeService: postalCodeService,
                    allocateInvoiceNumber: () =>
                        'RE-2026-${(sequence++).toString().padLeft(4, '0')}',
                    onSaveDraft: onSaveDraft ?? (_) {},
                  ),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openInvoiceEditor(
    WidgetTester tester, {
    required CompanyProfile companyProfile,
    ValueChanged<InvoiceDraft>? onSaveDraft,
  }) async {
    await tester.pumpWidget(
      invoiceEditorHost(
        companyProfile: companyProfile,
        onSaveDraft: onSaveDraft,
      ),
    );
    await tester.tap(find.byKey(const Key('open_invoice_editor')));
    await tester.pumpAndSettle();
  }

  Future<void> fillValidCustomer(
    WidgetTester tester, {
    String name = 'Beispiel Kunde AG',
  }) async {
    await tester.enterText(
      find.byKey(const Key('invoice_customer_name')),
      name,
    );
    await tester.enterText(
      find.byKey(const Key('invoice_customer_street')),
      'Bahnhofstrasse',
    );
    await tester.enterText(
      find.byKey(const Key('invoice_customer_house_number')),
      '5',
    );
    await tester.enterText(find.byKey(const Key('setup_postal_code')), '8340');
    await tester.enterText(find.byKey(const Key('setup_city')), 'Hinwil');
  }

  // ---------------------------------------------------------------------
  // Reine Logik-Tests (ohne Widget-Baum) für die Utility-Klassen.
  // ---------------------------------------------------------------------

  group('IBAN-Validierung (Modulo 97)', () {
    test('gültige IBAN (offizielles Beispiel) wird akzeptiert', () {
      expect(Iban.validate(_validIban), isNull);
    });

    test('IBAN mit falscher Prüfsumme wird abgelehnt', () {
      expect(Iban.validate('CH94 0076 2011 6238 5295 7'), isNotNull);
    });

    test('zu kurze/leere IBAN wird abgelehnt', () {
      expect(Iban.validate(''), isNotNull);
      expect(Iban.validate('CH93'), isNotNull);
    });

    test('formatForDisplay gruppiert in 4er-Blöcken', () {
      expect(
        Iban.formatForDisplay('CH9300762011623852957'),
        'CH93 0076 2011 6238 5295 7',
      );
    });
  });

  group('Schweizer Telefonnummer', () {
    test(
      'lokales Format, +41 und 0041 werden akzeptiert und gleich normalisiert',
      () {
        expect(SwissPhoneNumber.normalize('076 298 12 12'), '+41762981212');
        expect(SwissPhoneNumber.normalize('0762981212'), '+41762981212');
        expect(SwissPhoneNumber.normalize('+41 76 298 12 12'), '+41762981212');
        expect(SwissPhoneNumber.normalize('0041 76 298 12 12'), '+41762981212');
      },
    );

    test('formatForDisplay zeigt "+41 76 298 12 12"', () {
      expect(
        SwissPhoneNumber.formatForDisplay('+41762981212'),
        '+41 76 298 12 12',
      );
    });

    test('zu kurze, zu lange und Fantasienummern werden abgelehnt', () {
      expect(SwissPhoneNumber.isValid('12345'), isFalse);
      expect(SwissPhoneNumber.isValid('0762981212345'), isFalse);
      expect(SwissPhoneNumber.isValid('0000000000'), isFalse);
    });
  });

  group('Schweizer MWST-Nummer', () {
    test('formatForDisplay ergibt CHE-123.456.789 MWST', () {
      expect(
        SwissVatNumber.formatForDisplay('123456789'),
        'CHE-123.456.789 MWST',
      );
      expect(
        SwissVatNumber.formatForDisplay('CHE-123.456.789 MWST'),
        'CHE-123.456.789 MWST',
      );
    });

    test('ungültige Nummer wird abgelehnt', () {
      expect(SwissVatNumber.isValid('12345'), isFalse);
    });
  });

  group('PostalCodeService (amtliche Daten)', () {
    test('PLZ-Präfixsuche findet passende Orte, u.a. Hinwil bei 834', () {
      final results = postalCodeService.search('834');
      expect(results.map((e) => e.locality), contains('Hinwil'));
      expect(results.first.postalCode, '8340');
    });

    test('8180 findet Bülach', () {
      final results = postalCodeService.search('8180');
      expect(
        results.any((e) => e.locality == 'Bülach' && e.postalCode == '8180'),
        isTrue,
      );
    });

    test('8340 bzw. "Hin" findet Hinwil', () {
      expect(
        postalCodeService.search('8340').any((e) => e.locality == 'Hinwil'),
        isTrue,
      );
      expect(
        postalCodeService.search('Hin').any((e) => e.locality == 'Hinwil'),
        isTrue,
      );
    });

    test('Ortssuche ist unabhängig von Gross-/Kleinschreibung', () {
      final lower = postalCodeService.search('bül');
      final upper = postalCodeService.search('BÜL');
      expect(lower.any((e) => e.locality == 'Bülach'), isTrue);
      expect(upper.any((e) => e.locality == 'Bülach'), isTrue);
    });

    test('liefert höchstens 10 Vorschläge', () {
      expect(postalCodeService.search('8').length, lessThanOrEqualTo(10));
    });

    test('gültige PLZ/Ort-Kombination wird erkannt, ungültige abgelehnt', () {
      expect(postalCodeService.isValidCombination('8340', 'Hinwil'), isTrue);
      expect(postalCodeService.isValidCombination('8340', 'Bülach'), isFalse);
    });
  });

  // ---------------------------------------------------------------------
  // Startbildschirm & Demo-Modus
  // ---------------------------------------------------------------------

  group('Startbildschirm & Demo-Modus', () {
    testWidgets('Startbildschirm wird angezeigt', (WidgetTester tester) async {
      await tester.pumpWidget(
        BelegoApp(
          postalCodeService: postalCodeService,
          contactRepository: contactRepository,
        ),
      );

      expect(find.text('belego'), findsOneWidget);
      expect(find.text('Kostenlos registrieren'), findsOneWidget);
      expect(find.text('Anmelden'), findsOneWidget);
      expect(find.text('Demo ansehen'), findsOneWidget);
    });

    testWidgets('Demo-Modus zeigt Beispieldaten, Demo verlassen führt zurück', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(
        BelegoApp(
          postalCodeService: postalCodeService,
          contactRepository: contactRepository,
        ),
      );

      await tester.tap(find.text('Demo ansehen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Demo-Modus'), findsOneWidget);
      expect(find.textContaining('Müller Bau GmbH'), findsWidgets);

      await tester.tap(find.byKey(const Key('leave_demo_button')));
      await tester.pumpAndSettle();
      expect(find.text('Kostenlos registrieren'), findsOneWidget);
    });

    testWidgets('Vier Haupttabs bleiben verfügbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: RootShell(
            isDemoMode: false,
            postalCodeService: postalCodeService,
            contactRepository: contactRepository,
          ),
        ),
      );

      expect(find.text('Heute'), findsWidgets);
      expect(find.text('Assistent'), findsWidgets);
      expect(find.text('Dokumente'), findsWidgets);
      expect(find.text('Kontakte'), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------
  // Registrierung
  // ---------------------------------------------------------------------

  group('Registrierung', () {
    Future<void> openRegisterScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        BelegoApp(
          postalCodeService: postalCodeService,
          contactRepository: contactRepository,
        ),
      );
      await tester.tap(find.text('Kostenlos registrieren'));
      await tester.pumpAndSettle();
    }

    testWidgets('Pflichtfelder werden verlangt', (WidgetTester tester) async {
      await openRegisterScreen(tester);
      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Firma einrichten'), findsNothing);
    });

    testWidgets('unterschiedliche Passwörter werden abgelehnt', (
      WidgetTester tester,
    ) async {
      await openRegisterScreen(tester);
      await tester.enterText(
        find.byKey(const Key('register_first_name')),
        'Anna',
      );
      await tester.enterText(
        find.byKey(const Key('register_last_name')),
        'Muster',
      );
      await tester.enterText(
        find.byKey(const Key('register_email')),
        'anna@muster-ag.ch',
      );
      await tester.enterText(
        find.byKey(const Key('register_password')),
        'sicher123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password')),
        'anders123',
      );
      await tester.tap(find.byKey(const Key('register_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Passwörter stimmen nicht überein'), findsOneWidget);
      expect(find.text('Firma einrichten'), findsNothing);
    });

    testWidgets(
      'Vorname, Nachname und E-Mail werden in die Firmeneinrichtung übernommen',
      (WidgetTester tester) async {
        await openRegisterScreen(tester);
        await tester.enterText(
          find.byKey(const Key('register_first_name')),
          'Anna',
        );
        await tester.enterText(
          find.byKey(const Key('register_last_name')),
          'Muster',
        );
        await tester.enterText(
          find.byKey(const Key('register_email')),
          'Anna@Muster-AG.ch',
        );
        await tester.enterText(
          find.byKey(const Key('register_password')),
          'sicher123',
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password')),
          'sicher123',
        );
        await tester.tap(find.byKey(const Key('register_submit')));
        await tester.pumpAndSettle();

        final display = tester.widget<Text>(
          find.byKey(const Key('contact_person_display')),
        );
        expect(display.data, 'Anna Muster');
        expect(find.byKey(const Key('setup_first_name')), findsNothing);
        final emailField = tester.widget<TextFormField>(
          find.byKey(const Key('setup_business_email')),
        );
        expect(emailField.controller?.text, 'anna@muster-ag.ch');
      },
    );
  });

  // ---------------------------------------------------------------------
  // Firmeneinrichtung: Ansprechperson, Adresse, PLZ-Suche
  // ---------------------------------------------------------------------

  group('Firmeneinrichtung – Ansprechperson & Adresse', () {
    testWidgets('Ansprechperson ist änderbar', (WidgetTester tester) async {
      await tester.pumpWidget(wrapSetupScreen());
      await tester.tap(find.byKey(const Key('contact_person_edit_button')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('setup_first_name')),
        'Peter',
      );
      await tester.enterText(
        find.byKey(const Key('setup_last_name')),
        'Beispiel',
      );
      expect(find.text('Peter'), findsOneWidget);
      expect(find.text('Beispiel'), findsOneWidget);
    });

    testWidgets(
      'Eingegebene Daten bleiben beim Wechsel zwischen den Schritten erhalten',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapSetupScreen());
        await completeStep1(tester);
        expect(find.textContaining('Schritt 2 von 3'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.textContaining('Schritt 1 von 3'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('setup_company_name')),
              )
              .controller
              ?.text,
          'Muster AG',
        );
      },
    );
  });

  group('PLZ-/Ort-Autovervollständigung in der Firmeneinrichtung', () {
    testWidgets('Klick auf Vorschlag füllt PLZ und Ort, Liste schliesst sich', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await tester.enterText(find.byKey(const Key('setup_postal_code')), '834');
      await tester.pump();

      final suggestionKey = const Key('postal_suggestion_8340_Hinwil_ZH');
      await tester.ensureVisible(find.byKey(suggestionKey));
      await tester.pump();
      await tester.tap(find.byKey(suggestionKey));
      await tester.pump();

      expect(find.byKey(const Key('postal_code_suggestions')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('setup_postal_code')))
            .controller
            ?.text,
        '8340',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('setup_city')))
            .controller
            ?.text,
        'Hinwil',
      );
    });

    testWidgets('ungültige PLZ/Ort-Kombination wird abgelehnt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('setup_city')),
      );
      // PLZ 8340 gehört zu Hinwil, nicht zu Bülach.
      await tester.enterText(
        find.byKey(const Key('setup_postal_code')),
        '8340',
      );
      expect(field.validator?.call('Bülach'), isNotNull);
      expect(field.validator?.call('Hinwil'), isNull);
    });

    testWidgets('ist bei einem anderen Land als Schweiz deaktiviert', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await tester.tap(find.byKey(const Key('setup_country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutschland').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('setup_postal_code')), '834');
      await tester.pump();
      expect(find.byKey(const Key('postal_code_suggestions')), findsNothing);

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('setup_postal_code')),
      );
      expect(field.validator?.call('12345'), isNull);
    });
  });

  group('Finanzen (Schritt 2) – IBAN, kein QR-IBAN, MWST', () {
    testWidgets('Feld QR-IBAN ist vollständig entfernt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      expect(find.byKey(const Key('setup_iban')), findsOneWidget);
      expect(find.byKey(const Key('setup_qr_iban')), findsNothing);
      expect(find.textContaining('QR-IBAN'), findsNothing);
    });

    testWidgets('ungültige IBAN-Prüfsumme wird im Formular abgelehnt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      await tester.enterText(
        find.byKey(const Key('setup_iban')),
        'CH94 0076 2011 6238 5295 7',
      );
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Prüfsumme'), findsOneWidget);
      expect(find.textContaining('Schritt 3 von 3'), findsNothing);
    });

    testWidgets('MWST zeigt Zusatzfelder nur bei "Ja"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      expect(find.byKey(const Key('setup_vat_number')), findsNothing);
      expect(find.byKey(const Key('setup_vat_rate')), findsNothing);

      await tester.tap(find.text('Ja'));
      await tester.pump();
      expect(find.byKey(const Key('setup_vat_number')), findsOneWidget);
      expect(find.byKey(const Key('setup_vat_rate')), findsOneWidget);

      await tester.tap(find.text('Nein'));
      await tester.pump();
      expect(find.byKey(const Key('setup_vat_number')), findsNothing);
      expect(find.byKey(const Key('setup_vat_rate')), findsNothing);
    });

    testWidgets('MWST-Nein ergibt Standardsatz 0.0% in der Zusammenfassung', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();

      expect(find.text('Nein'), findsOneWidget);
      expect(find.textContaining('Standard-MWST-Satz'), findsNothing);
    });

    testWidgets('MWST-Ja mit 8.1% erscheint korrekt in der Zusammenfassung', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.text('Ja'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('setup_vat_number')),
        '123456789',
      );
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();

      expect(find.text('8.1 %'), findsOneWidget);
      expect(find.text('CHE-123.456.789 MWST'), findsOneWidget);
    });
  });

  testWidgets(
    'Vollständiger Ablauf ergibt eine korrekte, gut lesbare Abschluss-Zusammenfassung',
    (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      expect(find.textContaining('Schritt 2 von 3'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Schritt 3 von 3'), findsOneWidget);

      expect(find.text('Muster AG'), findsOneWidget);
      expect(find.text('Anna Muster'), findsOneWidget);
      expect(find.textContaining('Bahnhofstrasse 1'), findsOneWidget);
      expect(find.textContaining('8340 Hinwil'), findsOneWidget);
      expect(find.text('CH93 0076 2011 6238 5295 7'), findsOneWidget);
      expect(find.text('+41 76 298 12 12'), findsOneWidget);
      expect(find.text('30 Tage'), findsOneWidget);
      expect(find.text('Noch kein Logo ausgewählt'), findsWidgets);

      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // Rechnungseditor
  // ---------------------------------------------------------------------

  group('Rechnungseditor', () {
    testWidgets(
      '"Rechnung erstellen" öffnet den Editor, Rechnungsnummer ist nicht editierbar',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
              contactRepository: contactRepository,
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('invoice_customer_name')), findsOneWidget);
        expect(find.text('Wird beim Speichern vergeben'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('invoice_number')),
            matching: find.byType(TextField),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('mindestens ein Empfängername ist erforderlich', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapInvoiceEditor(companyProfile: testCompanyProfile()),
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('invoice_customer_name')),
      );
      expect(field.validator?.call(''), isNotNull);
      await tester.enterText(
        find.byKey(const Key('invoice_customer_first_name')),
        'Max',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_customer_last_name')),
        'Muster',
      );
      await tester.pump();
      final fieldAfter = tester.widget<TextFormField>(
        find.byKey(const Key('invoice_customer_name')),
      );
      expect(fieldAfter.validator?.call(''), isNull);
    });

    testWidgets(
      'Rechnungsempfänger nutzt dieselbe PLZ-/Ortssuche wie die Firma',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(companyProfile: testCompanyProfile()),
        );
        await tester.enterText(
          find.byKey(const Key('setup_postal_code')),
          '834',
        );
        await tester.pump();
        final suggestionKey = const Key('postal_suggestion_8340_Hinwil_ZH');
        await tester.ensureVisible(find.byKey(suggestionKey));
        await tester.pump();
        await tester.tap(find.byKey(suggestionKey));
        await tester.pump();

        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('setup_postal_code')))
              .controller
              ?.text,
          '8340',
        );
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('setup_city')))
              .controller
              ?.text,
          'Hinwil',
        );
      },
    );

    testWidgets(
      'eine erste leere Position ist vorhanden, hinzufügen/entfernen funktioniert',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(companyProfile: testCompanyProfile()),
        );
        expect(find.byKey(const Key('invoice_item_0')), findsOneWidget);
        expect(find.byKey(const Key('invoice_item_1')), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('invoice_add_item')));
        await tester.tap(find.byKey(const Key('invoice_add_item')));
        await tester.pump();
        expect(find.byKey(const Key('invoice_item_1')), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('invoice_item_remove_1')),
        );
        await tester.tap(find.byKey(const Key('invoice_item_remove_1')));
        await tester.pump();
        expect(find.byKey(const Key('invoice_item_1')), findsNothing);
        // Bei nur noch einer Position gibt es keinen Entfernen-Button mehr.
        expect(find.byKey(const Key('invoice_item_remove_0')), findsNothing);
      },
    );

    testWidgets('negative Menge und negativer Preis werden abgelehnt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapInvoiceEditor(companyProfile: testCompanyProfile()),
      );
      final qtyField = tester.widget<TextFormField>(
        find.byKey(const Key('invoice_item_quantity_0')),
      );
      expect(qtyField.validator?.call('-2'), isNotNull);
      expect(qtyField.validator?.call('2'), isNull);
      final priceField = tester.widget<TextFormField>(
        find.byKey(const Key('invoice_item_unit_price_0')),
      );
      expect(priceField.validator?.call('-10.00'), isNotNull);
      expect(priceField.validator?.call('0.00'), isNull);
    });

    testWidgets(
      'Positionsbetrag, Zwischensumme, MWST und Gesamtbetrag korrekt bei MWST-pflichtiger Firma',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(
            companyProfile: testCompanyProfile(isVatLiable: true, vatRate: 8.1),
          ),
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_quantity_0')),
          '2',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_unit_price_0')),
          '100.00',
        );
        await tester.pump();

        expect(
          find.text('Betrag: ${Money.formatRappen(20000)}'),
          findsOneWidget,
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('invoice_subtotal'))).data,
          Money.formatRappen(20000),
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('invoice_vat_total'))).data,
          Money.formatRappen(1620),
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('invoice_total_amount')))
              .data,
          Money.formatRappen(21620),
        );
      },
    );

    testWidgets('keine MWST bei nicht MWST-pflichtiger Firma', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapInvoiceEditor(
          companyProfile: testCompanyProfile(isVatLiable: false),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_description_0')),
        'Beratung',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_quantity_0')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_unit_price_0')),
        '100.00',
      );
      await tester.pump();

      expect(find.byKey(const Key('invoice_vat_total')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('invoice_total_amount'))).data,
        Money.formatRappen(20000),
      );
    });

    testWidgets(
      'mehrere unterschiedliche MWST-Sätze werden korrekt zusammengefasst',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(
            companyProfile: testCompanyProfile(isVatLiable: true, vatRate: 8.1),
          ),
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Ware A',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_quantity_0')),
          '1',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_unit_price_0')),
          '100.00',
        );
        await tester.pump();
        // Satz der ersten Position auf 2.6% ändern.
        await tester.ensureVisible(
          find.byKey(const Key('invoice_item_vat_rate_0')),
        );
        await tester.tap(find.byKey(const Key('invoice_item_vat_rate_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2.6 %').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('invoice_add_item')));
        await tester.tap(find.byKey(const Key('invoice_add_item')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_1')),
          'Ware B',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_quantity_1')),
          '1',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_unit_price_1')),
          '100.00',
        );
        await tester.pump();
        // Zweite Position bleibt beim Standardsatz 8.1%.

        // MWST gesamt = 2.60 + 8.10 = 10.70; Total = 200.00 + 10.70 = 210.70
        expect(
          tester.widget<Text>(find.byKey(const Key('invoice_vat_total'))).data,
          Money.formatRappen(1070),
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('invoice_total_amount')))
              .data,
          Money.formatRappen(21070),
        );
      },
    );

    testWidgets(
      'Fälligkeitsdatum wird aus Rechnungsdatum und Zahlungsfrist berechnet',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(
            companyProfile: testCompanyProfile(paymentTermDays: 30),
          ),
        );
        final invoiceDate = DateTime.now();
        expect(
          find.text(
            _swissDateFormat.format(invoiceDate.add(const Duration(days: 30))),
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('invoice_payment_term')),
          '10',
        );
        await tester.pump();
        expect(
          find.text(
            _swissDateFormat.format(invoiceDate.add(const Duration(days: 10))),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Pflichtfeldfehler werden angezeigt, nichts wird stillschweigend gespeichert',
      (WidgetTester tester) async {
        var saved = false;
        await tester.pumpWidget(
          wrapInvoiceEditor(
            companyProfile: testCompanyProfile(),
            onSaveDraft: (_) => saved = true,
          ),
        );

        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        expect(saved, isFalse);
        expect(
          find.text('Bitte die markierten Felder korrigieren.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('invoice_customer_name')), findsOneWidget);
      },
    );

    testWidgets(
      'Vorschau zeigt Absender- und Empfängerdaten (nach gültiger Eingabe)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(companyProfile: testCompanyProfile()),
        );
        await fillValidCustomer(tester);
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );

        await tester.ensureVisible(
          find.byKey(const Key('invoice_preview_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_preview_button')));
        await tester.pumpAndSettle();

        expect(find.text('Muster AG'), findsOneWidget);
        expect(find.text('Beispiel Kunde AG'), findsOneWidget);
      },
    );

    testWidgets('ohne Änderungen kann der Editor direkt verlassen werden', (
      WidgetTester tester,
    ) async {
      await openInvoiceEditor(tester, companyProfile: testCompanyProfile());
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(
        find.text('Möchtest du den Entwurf wirklich verwerfen?'),
        findsNothing,
      );
      expect(find.byKey(const Key('invoice_customer_name')), findsNothing);
    });

    testWidgets(
      'bei ungespeicherten Änderungen erscheint der Verwerfungsdialog',
      (WidgetTester tester) async {
        await openInvoiceEditor(tester, companyProfile: testCompanyProfile());
        await tester.enterText(
          find.byKey(const Key('invoice_customer_name')),
          'Etwas eingetippt',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(
          find.text('Möchtest du den Entwurf wirklich verwerfen?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('invoice_customer_name')), findsOneWidget);
      },
    );

    testWidgets(
      'Nummerierung: Abbrechen eines leeren Formulars verbraucht keine Nummer, keine Duplikate',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
              contactRepository: contactRepository,
            ),
          ),
        );

        // 1) Editor öffnen, etwas eintippen, dann verwerfen -> keine Nummer verbraucht.
        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('invoice_customer_name')),
          'Testeingabe',
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verwerfen'));
        await tester.pumpAndSettle();
        expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);

        // 2) Erste echte Rechnung speichern -> erhält RE-2026-0001.
        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester, name: 'Kunde Eins AG');
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();
        expect(find.text('RE-2026-0001'), findsOneWidget);

        // 3) Zweite Rechnung speichern -> erhält RE-2026-0002 (keine Duplikate).
        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester, name: 'Kunde Zwei AG');
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        expect(find.text('RE-2026-0001'), findsOneWidget);
        expect(find.text('RE-2026-0002'), findsOneWidget);
      },
    );

    testWidgets(
      'Entwurf speichern, im Tab Dokumente anzeigen, erneut öffnen und bearbeiten ohne Duplikat',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
              contactRepository: contactRepository,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester);
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        expect(find.text('Beispiel Kunde AG'), findsOneWidget);
        expect(find.text('Entwurf'), findsOneWidget);

        // Ein Entwurf ist noch keine gestellte Rechnung und zählt deshalb
        // nicht als offene Forderung in der Finanzübersicht auf „Heute“.
        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);

        // Entwurf erneut öffnen, Daten sind vollständig wiederhergestellt.
        await tester.tap(find.text('Dokumente').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beispiel Kunde AG'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('invoice_customer_name')),
              )
              .controller
              ?.text,
          'Beispiel Kunde AG',
        );
        expect(find.text('RE-2026-0001'), findsOneWidget);

        // Änderung speichern -> keine Kopie, weiterhin nur ein Dokument mit
        // derselben Nummer.
        await tester.enterText(
          find.byKey(const Key('invoice_title')),
          'Aktualisiert',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        expect(find.text('Beispiel Kunde AG'), findsOneWidget);
        expect(find.text('RE-2026-0001'), findsOneWidget);
        expect(find.textContaining('RE-2026-0002'), findsNothing);
      },
    );
  });

  testWidgets(
    'Abschluss der Firmeneinrichtung führt zum leeren Heute-Screen ohne Beispieldaten',
    (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();

      // Echter, leerer Zustand: keine erfundenen Rechnungen, Termine oder
      // Aufgaben, aber eine nützliche, nicht überladene Startseite.
      expect(find.textContaining('Guten'), findsOneWidget);
      expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);
      expect(find.text('Alles im grünen Bereich'), findsOneWidget);
      expect(
        find.text('Noch keine bezahlten Rechnungen diesen Monat.'),
        findsOneWidget,
      );
      expect(
        find.text('Für diesen Tag sind keine Termine vorhanden.'),
        findsOneWidget,
      );
      expect(find.text('Heute ist alles erledigt.'), findsOneWidget);
      expect(find.text('Müller Bau GmbH'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------
  // Eingabefeld-Gestaltung (sichtbar auch ohne Fokus, Fokus, Fehler)
  // ---------------------------------------------------------------------

  group('Eingabefeld-Gestaltung', () {
    testWidgets('unfokussiertes Feld hat sichtbare Füllung und Rahmen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      final decorationTheme = Theme.of(
        tester.element(find.byKey(const Key('setup_company_name'))),
      ).inputDecorationTheme;

      expect(decorationTheme.filled, isTrue);
      expect(decorationTheme.fillColor, AppColors.fieldFill);
      // Füllung darf weder reines Weiss noch identisch mit dem
      // Seitenhintergrund sein, damit das Feld eigenständig erkennbar ist.
      expect(decorationTheme.fillColor, isNot(Colors.white));
      expect(decorationTheme.fillColor, isNot(AppColors.background));

      final enabledBorder = decorationTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, AppColors.fieldBorder);
      expect(enabledBorder.borderSide.width, greaterThan(0));
    });

    testWidgets('fokussiertes Feld hat einen deutlich sky-blauen Rahmen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      final decorationTheme = Theme.of(
        tester.element(find.byKey(const Key('setup_company_name'))),
      ).inputDecorationTheme;
      final focusedBorder = decorationTheme.focusedBorder as OutlineInputBorder;

      expect(focusedBorder.borderSide.color, AppColors.sky600);
      final enabledBorder = decorationTheme.enabledBorder as OutlineInputBorder;
      expect(
        focusedBorder.borderSide.width,
        greaterThan(enabledBorder.borderSide.width),
      );
    });

    testWidgets(
      'fehlerhaftes Feld hat einen roten Rahmen mit deutscher Fehlermeldung',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapSetupScreen());
        final decorationTheme = Theme.of(
          tester.element(find.byKey(const Key('setup_company_name'))),
        ).inputDecorationTheme;
        final errorBorder = decorationTheme.errorBorder as OutlineInputBorder;
        expect(errorBorder.borderSide.color, AppColors.danger);

        await tester.tap(find.byKey(const Key('setup_primary_action')));
        await tester.pumpAndSettle();
        expect(find.text('Bitte Firmenname eingeben'), findsOneWidget);
      },
    );

    testWidgets(
      'automatisch berechnetes Feld unterscheidet sich optisch von editierbaren Feldern',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(companyProfile: testCompanyProfile()),
        );
        final autoFieldContainer = tester.widget<Container>(
          find.byKey(const Key('invoice_due_date')),
        );
        final decoration = autoFieldContainer.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.autoFieldFill);
        expect(decoration.color, isNot(AppColors.fieldFill));
        expect(
          find.descendant(
            of: find.byKey(const Key('invoice_due_date')),
            matching: find.byIcon(Icons.lock_outline),
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------
  // Reihenfolge der Adressfelder: PLZ/Ort vor Strasse/Hausnummer
  // ---------------------------------------------------------------------

  group('Reihenfolge der Adressfelder', () {
    testWidgets(
      'in der Firmeneinrichtung stehen PLZ/Ort vor Strasse/Hausnummer',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapSetupScreen());
        final postalCodeY = tester
            .getTopLeft(find.byKey(const Key('setup_postal_code')))
            .dy;
        final streetY = tester
            .getTopLeft(find.byKey(const Key('setup_street')))
            .dy;
        expect(postalCodeY, lessThan(streetY));
      },
    );

    testWidgets('im Rechnungseditor stehen PLZ/Ort vor Strasse/Hausnummer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapInvoiceEditor(companyProfile: testCompanyProfile()),
      );
      final postalCodeY = tester
          .getTopLeft(find.byKey(const Key('setup_postal_code')))
          .dy;
      final streetY = tester
          .getTopLeft(find.byKey(const Key('invoice_customer_street')))
          .dy;
      expect(postalCodeY, lessThan(streetY));
    });

    testWidgets('Auswahl eines Ortsvorschlags setzt PLZ und Ort', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapSetupScreen());
      // Vollständiger Ortsname statt nur "Hin": ergibt genau einen Treffer,
      // sodass der Vorschlag ohne Scrollen in der (lazy gebauten) Liste
      // sichtbar ist. Ein Teilstring wie "Hin" träfe mehrere Orte, von
      // denen "Hinwil" ausserhalb des sofort gebauten Viewports läge.
      await tester.enterText(find.byKey(const Key('setup_city')), 'Hinwil');
      await tester.pump();

      final suggestionKey = const Key('postal_suggestion_8340_Hinwil_ZH');
      await tester.ensureVisible(find.byKey(suggestionKey));
      await tester.pump();
      await tester.tap(find.byKey(suggestionKey));
      await tester.pump();

      expect(find.byKey(const Key('postal_code_suggestions')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('setup_postal_code')))
            .controller
            ?.text,
        '8340',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('setup_city')))
            .controller
            ?.text,
        'Hinwil',
      );
    });
  });

  // ---------------------------------------------------------------------
  // Rechnungspositionen: visuelle/funktionale Trennung, Entfernen-Regel
  // ---------------------------------------------------------------------

  group('Rechnungspositionen – Darstellung', () {
    testWidgets(
      'Positionen sind eigenständige, getrennte Container; nur ab Position 2 entfernbar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapInvoiceEditor(companyProfile: testCompanyProfile()),
        );

        expect(find.text('Position 1'), findsOneWidget);
        expect(find.byKey(const Key('invoice_item_remove_0')), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('invoice_add_item')));
        await tester.tap(find.byKey(const Key('invoice_add_item')));
        await tester.pump();

        expect(find.text('Position 1'), findsOneWidget);
        expect(find.text('Position 2'), findsOneWidget);
        // Jede Position ist ein eigener Container mit sichtbarem Rahmen.
        final firstBox = tester.widget<Container>(
          find.byKey(const Key('invoice_item_0')),
        );
        final secondBox = tester.widget<Container>(
          find.byKey(const Key('invoice_item_1')),
        );
        expect((firstBox.decoration! as BoxDecoration).border, isNotNull);
        expect((secondBox.decoration! as BoxDecoration).border, isNotNull);

        // Position 1 bleibt dauerhaft ohne Entfernen-Möglichkeit.
        expect(find.byKey(const Key('invoice_item_remove_0')), findsNothing);
        expect(find.byKey(const Key('invoice_item_remove_1')), findsOneWidget);

        await tester.tap(find.byKey(const Key('invoice_item_remove_1')));
        await tester.pump();
        expect(find.text('Position 2'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------
  // Firmenlogo: Validierung und Anzeige
  // ---------------------------------------------------------------------

  group('Firmenlogo', () {
    test('ungültiges Dateiformat wird abgelehnt', () {
      expect(LogoValidation.validateFileName('logo.pdf'), isNotNull);
      expect(LogoValidation.validateFileName('logo.gif'), isNotNull);
      expect(LogoValidation.validateFileName('logo.png'), isNull);
      expect(LogoValidation.validateFileName('LOGO.JPEG'), isNull);
    });

    test('Datei über 5 MB wird abgelehnt', () {
      expect(LogoValidation.validateSize(6 * 1024 * 1024), isNotNull);
      expect(LogoValidation.validateSize(5 * 1024 * 1024), isNull);
      expect(LogoValidation.validateSize(1024), isNull);
    });

    test('beschädigte/nicht lesbare Bilddaten werden erkannt', () async {
      final garbage = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(await LogoValidation.isDecodableImage(garbage), isFalse);
      expect(await LogoValidation.isDecodableImage(_testPngBytes), isTrue);
    });

    testWidgets(
      'ohne Logo wird ehrlich "Noch kein Logo ausgewählt" angezeigt',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: CompanyLogoSection(
                logoBytes: null,
                logoFileName: null,
                onLogoChanged: (_, _) {},
              ),
            ),
          ),
        );
        expect(find.text('Noch kein Logo ausgewählt'), findsOneWidget);
        expect(find.text('Entfernen'), findsNothing);
        expect(find.text('Auswählen'), findsOneWidget);
      },
    );

    testWidgets(
      'ein ausgewähltes Logo wird als Vorschau angezeigt und kann entfernt werden',
      (WidgetTester tester) async {
        Uint8List? changedBytes = _testPngBytes;
        String? changedName = 'firmenlogo.png';
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: AppTheme.light(),
                home: Scaffold(
                  body: CompanyLogoSection(
                    logoBytes: changedBytes,
                    logoFileName: changedName,
                    onLogoChanged: (bytes, name) => setState(() {
                      changedBytes = bytes;
                      changedName = name;
                    }),
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('firmenlogo.png'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Ersetzen'), findsOneWidget);
        expect(find.text('Entfernen'), findsOneWidget);

        await tester.tap(find.byKey(const Key('setup_logo_remove')));
        await tester.pump();

        expect(find.text('Noch kein Logo ausgewählt'), findsOneWidget);
        expect(changedBytes, isNull);
        expect(changedName, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------
  // Responsive Zusammenfassung: kein Overflow bei langen Werten
  // ---------------------------------------------------------------------

  testWidgets(
    'Zusammenfassung verursacht bei langen Werten und schmalem Bildschirm keinen Overflow',
    (WidgetTester tester) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(wrapSetupScreen());
      await tester.enterText(
        find.byKey(const Key('setup_company_name')),
        'Sehr lange Beispiel Firmenbezeichnung GmbH mit vielen Wörtern AG',
      );
      await tester.enterText(
        find.byKey(const Key('setup_street')),
        'Bahnhofstrasse',
      );
      await tester.enterText(find.byKey(const Key('setup_house_number')), '1');
      await tester.enterText(
        find.byKey(const Key('setup_postal_code')),
        '8340',
      );
      await tester.enterText(find.byKey(const Key('setup_city')), 'Hinwil');
      await tester.enterText(
        find.byKey(const Key('setup_phone')),
        '076 298 12 12',
      );
      await tester.enterText(
        find.byKey(const Key('setup_business_email')),
        'ein.sehr.langer.beispielhafter.emailadresse.abschnitt@beispielunternehmen-mit-langem-namen.ch',
      );
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Schritt 3 von 3'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // „Heute“ – Kopfbereich, Firmenlogo, Finanzübersicht
  // ---------------------------------------------------------------------

  group('„Heute“ – Kopfbereich und Finanzübersicht', () {
    testWidgets('Firmenlogo wird aus der Firmeneinrichtung übernommen', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      final profile = testCompanyProfile()
        ..logoBytes = _testPngBytes
        ..logoFileName = 'logo.png';
      await tester.pumpWidget(wrapRootShell(companyProfile: profile));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Ohne Firmenlogo erscheint der Platzhalter', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(
        wrapRootShell(companyProfile: testCompanyProfile()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      // Initialen von "Muster AG".
      expect(find.text('MA'), findsOneWidget);
    });

    testWidgets('Begrüssung und Datum werden angezeigt', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      expect(find.textContaining('Guten'), findsOneWidget);
      expect(find.textContaining('Anna'), findsOneWidget);
      final expectedDate = DateFormat(
        'EEEE, d. MMMM yyyy',
        'de_CH',
      ).format(DateTime.now());
      expect(find.text(expectedDate), findsOneWidget);
    });

    testWidgets('Finanzwerte werden aus Rechnungsdaten berechnet', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(
        wrapRootShell(companyProfile: testCompanyProfile(isVatLiable: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
      await tester.pumpAndSettle();
      await fillValidCustomer(tester);
      await tester.enterText(
        find.byKey(const Key('invoice_item_description_0')),
        'Beratung',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_quantity_0')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_unit_price_0')),
        '100',
      );
      await tester.ensureVisible(
        find.byKey(const Key('invoice_save_draft_button')),
      );
      await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
      await tester.pumpAndSettle();

      // Ein Entwurf zählt noch nicht als offene Rechnung – erst nach
      // „Rechnung stellen“ im Dokumente-Tab.
      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();
      expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);

      await tester.tap(find.text('Dokumente').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rechnung stellen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();

      expect(find.text(Money.formatRappen(20000)), findsOneWidget);
      expect(find.text('1 offene Rechnung'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // Kalender – Termine hinzufügen, bearbeiten, löschen
  // ---------------------------------------------------------------------

  group('Kalender – Termine verwalten', () {
    Future<void> addAppointment(WidgetTester tester, String title) async {
      await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        title,
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('Termin kann hinzugefügt werden', (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      await addAppointment(tester, 'Kundentermin');

      expect(find.text('Kundentermin'), findsOneWidget);
      expect(
        find.text('Für diesen Tag sind keine Termine vorhanden.'),
        findsNothing,
      );
    });

    testWidgets('Termin kann bearbeitet werden', (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await addAppointment(tester, 'Kundentermin');

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('appointment_title_field')),
            )
            .controller
            ?.text,
        'Kundentermin',
      );
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Kundentermin (verschoben)',
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Kundentermin (verschoben)'), findsOneWidget);
      expect(find.text('Kundentermin'), findsNothing);
    });

    testWidgets('Termin kann gelöscht werden', (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await addAppointment(tester, 'Kundentermin');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(find.text('Kundentermin'), findsNothing);
      expect(
        find.text('Für diesen Tag sind keine Termine vorhanden.'),
        findsOneWidget,
      );
    });
  });

  group('Termine – Validierung', () {
    test('Ungültige Terminzeiten werden abgelehnt', () {
      expect(Validators.appointmentEndTime(600, 500), isNotNull);
      expect(Validators.appointmentEndTime(600, 600), isNull);
      expect(Validators.appointmentEndTime(600, 700), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Aufgaben hinzufügen, erledigen/öffnen, löschen
  // ---------------------------------------------------------------------

  group('Aufgaben verwalten', () {
    Future<void> addTask(WidgetTester tester, String title) async {
      await tester.tap(find.byKey(const Key('add_task_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('task_title_field')), title);
      await tester.tap(find.byKey(const Key('task_save_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('Aufgabe kann hinzugefügt werden', (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      await addTask(tester, 'Material bestellen');

      expect(find.text('Material bestellen'), findsOneWidget);
      expect(find.text('Heute ist alles erledigt.'), findsNothing);
    });

    testWidgets('Aufgabe kann erledigt und wieder geöffnet werden', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await addTask(tester, 'Material bestellen');

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(find.text('Heute ist alles erledigt.'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.text('Heute ist alles erledigt.'), findsNothing);
    });

    testWidgets('Aufgabe kann gelöscht werden', (WidgetTester tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await addTask(tester, 'Material bestellen');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Material bestellen'), findsNothing);
      expect(find.text('Heute ist alles erledigt.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // Responsive „Heute“-Startseite: kein Overflow
  // ---------------------------------------------------------------------

  group('Responsive „Heute“-Startseite', () {
    testWidgets('Schmales Smartphone-Layout verursacht keinen Overflow', (
      WidgetTester tester,
    ) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(320, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      final profile = testCompanyProfile()
        ..companyName = 'Sehr lange Beispiel Firmenbezeichnung GmbH';
      await tester.pumpWidget(wrapRootShell(companyProfile: profile));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Ein länglicher Termintitel zum Testen des Zeilenumbruchs',
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Breites Web-Layout verursacht keinen Overflow', (
      WidgetTester tester,
    ) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Keine doppelten Aktionen auf „Heute“
  // ---------------------------------------------------------------------

  group('Keine doppelten Aktionen auf „Heute“', () {
    testWidgets('„Termin hinzufügen“ erscheint nur einmal', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      expect(find.text('Termin hinzufügen'), findsOneWidget);
      expect(
        find.byKey(const Key('quick_action_add_appointment')),
        findsNothing,
      );
    });

    testWidgets('„Aufgabe hinzufügen“ erscheint nur einmal', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      expect(find.text('Aufgabe hinzufügen'), findsOneWidget);
      expect(find.byKey(const Key('add_task_button')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------
  // Kategorie-Farben im Kalender (Punkte + Terminliste)
  // ---------------------------------------------------------------------

  group('Kategorie-Farben im Kalender', () {
    Key todayKey() {
      final now = DateTime.now();
      return Key('calendar_day_${now.year}-${now.month}-${now.day}');
    }

    List<Color> dotColors(WidgetTester tester) {
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(todayKey()),
          matching: find.byType(Container),
        ),
      );
      return [
        for (final container in containers)
          if (container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).shape == BoxShape.circle)
            (container.decoration! as BoxDecoration).color!,
      ];
    }

    testWidgets('Geschäftlicher Termin zeigt einen blauen Punkt', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Kundenbesuch',
      );
      // Kategorie bleibt auf der Standardauswahl „Geschäftlich“.
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      final colors = dotColors(tester);
      expect(colors, contains(AppColors.sky600));
      expect(colors, isNot(contains(AppColors.privateOrange)));

      // Auch die Kategorie-Markierung in der Terminliste (der schmale
      // Farbbalken links neben dem Termin) verwendet dieselbe Farbe.
      final categoryBar = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == 4 &&
              w.decoration is BoxDecoration,
        ),
      );
      expect(
        categoryBar.any(
          (c) => (c.decoration! as BoxDecoration).color == AppColors.sky600,
        ),
        isTrue,
      );
    });

    testWidgets('Privater Termin zeigt einen orangen Punkt', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Familienessen',
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('appointment_category_selector')),
          matching: find.text('Privat'),
        ),
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      final colors = dotColors(tester);
      expect(colors, contains(AppColors.privateOrange));
      expect(colors, isNot(contains(AppColors.sky600)));
    });

    testWidgets('Tag mit beiden Kategorien zeigt beide Marker', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Kundenbesuch',
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_appointment_inline_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Familienessen',
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('appointment_category_selector')),
          matching: find.text('Privat'),
        ),
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      final colors = dotColors(tester);
      expect(colors, contains(AppColors.sky600));
      expect(colors, contains(AppColors.privateOrange));
    });
  });

  // ---------------------------------------------------------------------
  // Optionale Kontaktsuche im Termin-Dialog
  // ---------------------------------------------------------------------

  group('Kontaktsuche im Termin-Dialog', () {
    testWidgets('Termin kann mit optionalem Kontakt gespeichert werden', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();

      // Im Demo-Modus sind bereits Termine vorhanden, daher der inline
      // „Termin hinzufügen“-Button statt des Leerzustand-Buttons.
      await tester.tap(find.byKey(const Key('add_appointment_inline_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Vertragsbesprechung',
      );
      await tester.enterText(
        find.byKey(const Key('appointment_contact_search')),
        'Sonnenhof',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('appointment_contact_suggestions')),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('Sonnenhof Gartenbau AG').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('verknüpft'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Vertragsbesprechung'), findsOneWidget);
    });

    testWidgets(
      'Termin kann ohne Kontakt gespeichert werden, ehrlicher Hinweis ohne Kontakte',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        // Echter (nicht-Demo) Zustand: noch keine Kontakte vorhanden.
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Noch keine Kontakte gespeichert. Der Termin kann trotzdem '
            'erstellt werden.',
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('appointment_title_field')),
          'Kurzer Anruf',
        );
        await tester.tap(find.byKey(const Key('appointment_save_button')));
        await tester.pumpAndSettle();

        expect(find.text('Kurzer Anruf'), findsOneWidget);
      },
    );

    testWidgets(
      'Termin-Dialog verwendet die zentral definierte Feld-Decoration',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
        await tester.pumpAndSettle();

        final decorationTheme = Theme.of(
          tester.element(find.byKey(const Key('appointment_title_field'))),
        ).inputDecorationTheme;
        expect(decorationTheme.filled, isTrue);
        expect(decorationTheme.fillColor, AppColors.fieldFill);
        final enabledBorder =
            decorationTheme.enabledBorder as OutlineInputBorder;
        expect(enabledBorder.borderSide.color, AppColors.fieldBorder);
        expect(enabledBorder.borderSide.width, greaterThan(0));
      },
    );
  });

  // ---------------------------------------------------------------------
  // Dokumentstatus: Entwurf / Offen / Bezahlt / Überfällig
  // ---------------------------------------------------------------------

  group('InvoiceDraft – Status und Überfälligkeit', () {
    test('offene, überfällige Rechnung wird als überfällig erkannt', () {
      final draft = InvoiceDraft(
        invoiceDate: DateTime.now().subtract(const Duration(days: 40)),
        paymentTermDays: 10,
      )..status = InvoiceStatus.open;
      expect(draft.isOverdue, isTrue);
    });

    test('bezahlte Rechnung gilt nie als überfällig', () {
      final draft = InvoiceDraft(
        invoiceDate: DateTime.now().subtract(const Duration(days: 40)),
        paymentTermDays: 10,
      )..status = InvoiceStatus.paid;
      expect(draft.isOverdue, isFalse);
    });

    test('Entwurf gilt nie als überfällig', () {
      final draft = InvoiceDraft(
        invoiceDate: DateTime.now().subtract(const Duration(days: 40)),
        paymentTermDays: 10,
      );
      expect(draft.status, InvoiceStatus.draft);
      expect(draft.isOverdue, isFalse);
    });

    test(
      'offene Rechnung mit zukünftigem Fälligkeitsdatum ist nicht überfällig',
      () {
        final draft = InvoiceDraft(
          invoiceDate: DateTime.now(),
          paymentTermDays: 30,
        )..status = InvoiceStatus.open;
        expect(draft.isOverdue, isFalse);
      },
    );
  });

  group('Dokumentfilter und Statuswechsel', () {
    testWidgets(
      'Entwurf erscheint nicht unter „Offen“, Dokumentfilter funktionieren korrekt',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester, name: 'Entwurf Kunde AG');
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        // Alle: sichtbar. Entwürfe: sichtbar. Offen/Bezahlt/Überfällig: nicht.
        expect(find.text('Entwurf Kunde AG'), findsOneWidget);
        await tester.tap(find.byKey(const Key('documents_filter_open')));
        await tester.pumpAndSettle();
        expect(find.text('Entwurf Kunde AG'), findsNothing);
        expect(find.text('Keine Dokumente für diesen Filter.'), findsOneWidget);

        await tester.tap(find.byKey(const Key('documents_filter_draft')));
        await tester.pumpAndSettle();
        expect(find.text('Entwurf Kunde AG'), findsOneWidget);

        // Rechnung stellen -> erscheint jetzt unter „Offen“, nicht mehr unter
        // „Entwürfe“.
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rechnung stellen'));
        await tester.pumpAndSettle();

        expect(find.text('Entwurf Kunde AG'), findsNothing);
        await tester.tap(find.byKey(const Key('documents_filter_open')));
        await tester.pumpAndSettle();
        expect(find.text('Entwurf Kunde AG'), findsOneWidget);

        // Als bezahlt markieren -> erscheint unter „Bezahlt“.
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Als bezahlt markieren'));
        await tester.pumpAndSettle();
        expect(find.text('Bezahlt'), findsOneWidget);

        await tester.tap(find.byKey(const Key('documents_filter_paid')));
        await tester.pumpAndSettle();
        expect(find.text('Entwurf Kunde AG'), findsOneWidget);

        await tester.tap(find.byKey(const Key('documents_filter_all')));
        await tester.pumpAndSettle();
        expect(find.text('Entwurf Kunde AG'), findsOneWidget);
      },
    );

    testWidgets(
      '„Als bezahlt markieren“ ändert den Status und aktualisiert den Umsatz',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(
          wrapRootShell(companyProfile: testCompanyProfile(isVatLiable: false)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester);
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_unit_price_0')),
          '300',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        // Entwurf: kein Umsatz.
        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Noch keine bezahlten Rechnungen diesen Monat.'),
          findsOneWidget,
        );

        // Rechnung stellen (Offen): weiterhin kein Umsatz.
        await tester.tap(find.text('Dokumente').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rechnung stellen'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Noch keine bezahlten Rechnungen diesen Monat.'),
          findsOneWidget,
        );
        expect(find.text('1 offene Rechnung'), findsOneWidget);

        // Als bezahlt markieren: zählt jetzt zum Umsatz, nicht mehr offen.
        await tester.tap(find.text('Dokumente').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Als bezahlt markieren'));
        await tester.pumpAndSettle();
        // „Bezahlt“ erscheint sowohl als Status-Chip auf der Zeile als auch
        // als Beschriftung des Filter-Chips – mindestens einmal genügt hier.
        expect(find.text('Bezahlt'), findsWidgets);

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(find.text(Money.formatRappen(30000)), findsOneWidget);
        expect(find.text('Keine offenen Rechnungen.'), findsOneWidget);
      },
    );

    testWidgets(
      'Zurücksetzen auf „Offen“ entfernt die Rechnung wieder aus dem Umsatz',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(
          wrapRootShell(companyProfile: testCompanyProfile(isVatLiable: false)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();
        await fillValidCustomer(tester);
        await tester.enterText(
          find.byKey(const Key('invoice_item_description_0')),
          'Beratung',
        );
        await tester.enterText(
          find.byKey(const Key('invoice_item_unit_price_0')),
          '300',
        );
        await tester.ensureVisible(
          find.byKey(const Key('invoice_save_draft_button')),
        );
        await tester.tap(find.byKey(const Key('invoice_save_draft_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rechnung stellen'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Als bezahlt markieren'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Noch keine bezahlten Rechnungen diesen Monat.'),
          findsNothing,
        );

        await tester.tap(find.text('Dokumente').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Als offen markieren'));
        await tester.pumpAndSettle();
        // Statuswechsel von „Bezahlt“ zurück auf „Offen“ zeigt eine
        // Sicherheitsabfrage, die zuerst bestätigt werden muss.
        await tester.tap(find.text('Bestätigen'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Noch keine bezahlten Rechnungen diesen Monat.'),
          findsOneWidget,
        );
        expect(find.text('1 offene Rechnung'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------
  // Neues „Heute“-Design: Kopfbereich, Schnellaktionen, Kalendernavigation
  // ---------------------------------------------------------------------

  group('Neues Heute-Design – Struktur und Navigation', () {
    testWidgets('Kopfbereich (Belego-Markenleiste) erscheint nur einmal', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('top_bar_menu_button')), findsOneWidget);
      expect(
        find.byKey(const Key('top_bar_notifications_button')),
        findsOneWidget,
      );
      expect(find.text('Belego'), findsOneWidget);
    });

    testWidgets(
      'Schnellaktionen erscheinen mit allen vier Aktionen genau einmal',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('quick_action_create_invoice')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('quick_action_create_offer')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('quick_action_create_contract')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('quick_action_add_contact')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Wochennavigation: vorherige/nächste Woche funktioniert', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      final labelFinder = find.byKey(const Key('calendar_label_button'));
      String labelText() => tester
          .widget<Text>(
            find.descendant(of: labelFinder, matching: find.byType(Text)),
          )
          .data!;
      final before = labelText();

      await tester.tap(find.byKey(const Key('calendar_next_button')));
      await tester.pumpAndSettle();
      expect(labelText(), isNot(equals(before)));

      await tester.tap(find.byKey(const Key('calendar_prev_button')));
      await tester.pumpAndSettle();
      expect(labelText(), equals(before));
    });

    testWidgets('Monatsansicht kann geöffnet werden', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_month_grid')), findsNothing);
      await tester.tap(find.text('Monat'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar_month_grid')), findsOneWidget);
    });

    testWidgets(
      'Termin kann für ein zukünftiges Datum in der Monatsansicht gespeichert werden',
      (WidgetTester tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Monat'));
        await tester.pumpAndSettle();
        // Zwei Monate weiter, damit ein eindeutig zukünftiger Tag im
        // sichtbaren Raster liegt.
        await tester.tap(find.byKey(const Key('calendar_next_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('calendar_next_button')));
        await tester.pumpAndSettle();

        final now = DateTime.now();
        final target = DateTime(now.year, now.month + 2, 15);
        await tester.tap(
          find.byKey(
            Key('calendar_day_${target.year}-${target.month}-${target.day}'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('appointment_title_field')),
          'Zukünftiger Termin',
        );
        expect(
          find.text('Dieses Datum liegt in der Vergangenheit.'),
          findsNothing,
        );
        await tester.tap(find.byKey(const Key('appointment_save_button')));
        await tester.pumpAndSettle();

        expect(find.text('Zukünftiger Termin'), findsOneWidget);
      },
    );

    testWidgets('Geschäftliche Aufgabe wird blau, private orange markiert', (
      WidgetTester tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      Future<void> addTaskWithCategory(String title, Key categoryKey) async {
        await tester.tap(find.byKey(const Key('add_task_empty_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('task_title_field')),
          title,
        );
        await tester.tap(find.byKey(categoryKey));
        await tester.tap(find.byKey(const Key('task_save_button')));
        await tester.pumpAndSettle();
      }

      await addTaskWithCategory(
        'Angebot senden',
        const Key('task_category_business'),
      );
      await addTaskWithCategory('Zahnarzt', const Key('task_category_private'));

      final bars = tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(const Key('tasks_section')),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 4 &&
                w.decoration is BoxDecoration,
          ),
        ),
      );
      final colors = bars
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(colors, contains(AppColors.businessBlue));
      expect(colors, contains(AppColors.privateOrange));
    });
  });

  group('Zentrale Eingabefeld-Gestaltung', () {
    test('Eingabefelder verwenden die zentrale, klar sichtbare Dekoration', () {
      final theme = AppTheme.light().inputDecorationTheme;
      expect(theme.filled, isTrue);
      expect(theme.fillColor, AppColors.fieldFill);
      expect(
        (theme.enabledBorder! as OutlineInputBorder).borderSide.color,
        AppColors.fieldBorder,
      );
      expect(
        (theme.focusedBorder! as OutlineInputBorder).borderSide.color,
        AppColors.sky600,
      );
      expect(
        (theme.errorBorder! as OutlineInputBorder).borderSide.color,
        AppColors.danger,
      );
    });
  });

  // ---------------------------------------------------------------------
  // Finanzkarten: immer nebeneinander, auch auf schmalen Smartphones
  // ---------------------------------------------------------------------

  group('Finanzkarten – responsives Nebeneinander ohne Overflow', () {
    // Demo-Werte aus `TodayScreenState._buildDemoInvoices` (siehe dort):
    // nur DEMO1 (CHF 1'240.00) ist diesen Monat bezahlt; DEMO2 (CHF 950.00)
    // ist offen und überfällig, DEMO3 (CHF 380.50) offen und nicht
    // überfällig -> Offene Rechnungen gesamt CHF 1'330.50, 2 Stück.
    const expectedRevenue = 124000;
    const expectedOpenTotal = 133050;
    const expectedOverdueTotal = 95000;

    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });
      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();
    }

    void expectCardsSideBySideWithinScreen(WidgetTester tester, double width) {
      final revenueRect = tester.getRect(
        find.byKey(const Key('finance_card_revenue')),
      );
      final openRect = tester.getRect(
        find.byKey(const Key('finance_card_open')),
      );
      final overdueRect = tester.getRect(
        find.byKey(const Key('finance_card_overdue')),
      );

      // Nebeneinander statt untereinander: gleiche vertikale Position,
      // aufsteigende horizontale Position.
      expect(revenueRect.top, closeTo(openRect.top, 0.5));
      expect(openRect.top, closeTo(overdueRect.top, 0.5));
      expect(revenueRect.left, lessThan(openRect.left));
      expect(openRect.left, lessThan(overdueRect.left));

      // Keine Karte liegt ausserhalb des sichtbaren Bereichs.
      expect(revenueRect.left, greaterThanOrEqualTo(-0.5));
      expect(overdueRect.right, lessThanOrEqualTo(width + 0.5));

      // CHF-Beträge sind vollständig (nicht gekürzt/abgeschnitten) vorhanden.
      expect(find.text(Money.formatRappen(expectedRevenue)), findsOneWidget);
      expect(find.text(Money.formatRappen(expectedOpenTotal)), findsOneWidget);
      expect(
        find.text(Money.formatRappen(expectedOverdueTotal)),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    }

    for (final width in [320.0, 360.0, 375.0, 390.0, 430.0]) {
      testWidgets(
        'Alle drei Finanzkarten stehen bei ${width.toInt()}px nebeneinander, '
        'ohne Overflow und mit vollständigen CHF-Beträgen',
        (tester) async {
          await pumpAtWidth(tester, width);
          expectCardsSideBySideWithinScreen(tester, width);
        },
      );
    }

    testWidgets(
      'Kein horizontaler Scrollbereich für die Finanzkarten auf Smartphonebreite',
      (tester) async {
        await pumpAtWidth(tester, 320);

        final scrollableAncestors = tester.widgetList<Scrollable>(
          find.ancestor(
            of: find.byKey(const Key('finance_card_revenue')),
            matching: find.byType(Scrollable),
          ),
        );
        final hasHorizontalScrollable = scrollableAncestors.any(
          (s) =>
              s.axisDirection == AxisDirection.left ||
              s.axisDirection == AxisDirection.right,
        );
        expect(hasHorizontalScrollable, isFalse);
      },
    );

    testWidgets(
      'Finanzkarten stehen im breiten Weblayout weiterhin korrekt nebeneinander',
      (tester) async {
        await pumpAtWidth(tester, 1600);
        expectCardsSideBySideWithinScreen(tester, 1600);
      },
    );

    testWidgets('Farblogik der Finanzkarten bleibt korrekt (Blau/Orange/Rot)', (
      tester,
    ) async {
      await pumpAtWidth(tester, 375);

      Color firstIconColor(String key) => tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(Icon),
            ),
          )
          .first
          .color!;

      expect(firstIconColor('finance_card_revenue'), AppColors.sky600);
      expect(firstIconColor('finance_card_open'), AppColors.privateOrange);
      // Demo-Daten enthalten eine überfällige Rechnung -> Rot statt Grün.
      expect(firstIconColor('finance_card_overdue'), AppColors.danger);
    });
  });

  // ---------------------------------------------------------------------
  // Hintergrundwellen: einmalige, akkuschonende Animation
  // ---------------------------------------------------------------------

  group('Hintergrundwellen-Animation', () {
    testWidgets('Wellenanimation endet vollständig und läuft nicht endlos', (
      tester,
    ) async {
      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      // Die Animation dauert ca. 900ms – hier grosszügig darüber hinaus
      // pumpen, damit sie sicher abgeschlossen ist.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Deutlich länger weiterlaufen lassen: bei einer fälschlich endlos
      // laufenden Animation (Loop/Ticker ohne Stopp) wäre hier weiterhin ein
      // Frame eingeplant.
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Reduzierte Bewegung überspringt die Wellenanimation', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pump();

      // Ohne Bewegung wird sofort der Endzustand gezeigt, es läuft kein
      // weiterer Animationsframe.
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Kontakte
  // ---------------------------------------------------------------------

  group('Kontakte', () {
    Future<void> openContactsTab(WidgetTester tester) async {
      await tester.tap(find.text('Kontakte').last);
      await tester.pumpAndSettle();
    }

    Future<void> tapAddContact(WidgetTester tester) async {
      final emptyButton = find.byKey(const Key('contacts_empty_add_button'));
      if (emptyButton.evaluate().isNotEmpty) {
        await tester.tap(emptyButton);
      } else {
        await tester.tap(find.byKey(const Key('contacts_add_button')));
      }
      await tester.pumpAndSettle();
    }

    Future<void> fillContactAddress(
      WidgetTester tester, {
      String street = 'Musterstrasse',
      String houseNumber = '1',
      String postalCode = '8340',
      String city = 'Hinwil',
    }) async {
      await tester.enterText(find.byKey(const Key('contact_street')), street);
      await tester.enterText(
        find.byKey(const Key('contact_house_number')),
        houseNumber,
      );
      await tester.enterText(
        find.byKey(const Key('setup_postal_code')),
        postalCode,
      );
      await tester.enterText(find.byKey(const Key('setup_city')), city);
    }

    testWidgets('1: Kontakte-Leerzustand wird korrekt angezeigt', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);

      expect(find.byKey(const Key('contacts_empty_state')), findsOneWidget);
      expect(find.text('Noch keine Kontakte'), findsOneWidget);
      expect(
        find.byKey(const Key('contacts_empty_add_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      '2, 8, 10, 11: Kontakt erstellen, im Kundenfilter sichtbar, per Suche über Firma/E-Mail/PLZ/Ort auffindbar',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Beispiel Gartenbau AG',
        );
        await fillContactAddress(tester);
        await tester.enterText(
          find.byKey(const Key('contact_email')),
          'info@beispiel-gartenbau.example',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        expect(find.text('Beispiel Gartenbau AG'), findsOneWidget);

        await tester.tap(find.byKey(const Key('contacts_filter_customers')));
        await tester.pumpAndSettle();
        expect(find.text('Beispiel Gartenbau AG'), findsOneWidget);

        await tester.tap(find.byKey(const Key('contacts_filter_suppliers')));
        await tester.pumpAndSettle();
        expect(find.text('Beispiel Gartenbau AG'), findsNothing);

        await tester.tap(find.byKey(const Key('contacts_filter_all')));
        await tester.pumpAndSettle();

        for (final query in [
          'Gartenbau',
          'beispiel-gartenbau',
          '8340',
          'Hinwil',
        ]) {
          await tester.enterText(
            find.byKey(const Key('contacts_search_field')),
            query,
          );
          await tester.pump();
          expect(
            find.text('Beispiel Gartenbau AG'),
            findsOneWidget,
            reason: 'Suche nach "$query" sollte den Kontakt finden',
          );
        }

        await tester.enterText(
          find.byKey(const Key('contacts_search_field')),
          'Nichts-Passendes-Xyz',
        );
        await tester.pump();
        expect(find.text('Beispiel Gartenbau AG'), findsNothing);
      },
    );

    testWidgets(
      '9, 10: Lieferant erscheint im Lieferantenfilter, kombinierter Kontakt in beiden Filtern',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);

        await tapAddContact(tester);
        await tester.tap(find.byKey(const Key('contact_type_customer')));
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Baustoffe Muster GmbH',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tapAddContact(tester);
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Muster Treuhand AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('contacts_filter_suppliers')));
        await tester.pumpAndSettle();
        expect(find.text('Baustoffe Muster GmbH'), findsOneWidget);
        expect(find.text('Muster Treuhand AG'), findsOneWidget);

        await tester.tap(find.byKey(const Key('contacts_filter_customers')));
        await tester.pumpAndSettle();
        expect(find.text('Baustoffe Muster GmbH'), findsNothing);
        expect(find.text('Muster Treuhand AG'), findsOneWidget);
      },
    );

    testWidgets('3: Firmenkontakt verlangt einen Firmennamen', (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);

      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Bitte Firmenname eingeben'), findsOneWidget);
      // Der Dialog bleibt offen, es wurde nichts gespeichert.
      expect(find.byKey(const Key('contact_save_button')), findsOneWidget);
    });

    testWidgets('4: Privatperson verlangt mindestens einen Namen', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('contact_is_company_selector')),
          matching: find.text('Privatperson'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Bitte Vorname oder Nachname eingeben'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('contact_first_name')),
        'Laura',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Laura'), findsOneWidget);
    });

    testWidgets(
      '12-14: E-Mail-, Telefon- und IBAN-Validierung im Kontaktformular',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        final emailField = tester.widget<TextFormField>(
          find.byKey(const Key('contact_email')),
        );
        expect(emailField.validator?.call('keine-email'), isNotNull);
        expect(emailField.validator?.call('info@beispiel.ch'), isNull);

        final phoneField = tester.widget<TextFormField>(
          find.byKey(const Key('contact_phone')),
        );
        expect(phoneField.validator?.call('076 298 12 12'), isNull);

        // Die IBAN ist nur bei einer Lieferantenrolle sichtbar (siehe
        // Abschnitt „Zahlungsangaben“) – für einen reinen Kunden erscheint
        // das Feld gar nicht erst.
        expect(find.byKey(const Key('contact_iban')), findsNothing);
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.pumpAndSettle();

        final ibanField = tester.widget<TextFormField>(
          find.byKey(const Key('contact_iban')),
        );
        // Gleiche IBAN wie [_validIban], aber mit falscher Prüfsumme (94
        // statt 93) – siehe Gruppe „IBAN-Validierung“.
        expect(
          ibanField.validator?.call('CH94 0076 2011 6238 5295 7'),
          isNotNull,
        );
        expect(ibanField.validator?.call(_validIban), isNull);
      },
    );

    testWidgets(
      '13, 15: Telefon und IBAN werden beim Speichern normalisiert angezeigt',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        // IBAN ist nur bei (auch) Lieferantenrolle sichtbar/relevant.
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Normalisierung AG',
        );
        await fillContactAddress(tester);
        await tester.enterText(
          find.byKey(const Key('contact_phone')),
          '076 298 12 12',
        );
        await tester.enterText(
          find.byKey(const Key('contact_iban')),
          _validIban,
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Normalisierung AG'));
        await tester.pumpAndSettle();
        expect(find.text('+41 76 298 12 12'), findsOneWidget);
        expect(find.text('CH93 0076 2011 6238 5295 7'), findsOneWidget);
      },
    );

    testWidgets(
      '5, 6: Kontakt kann bearbeitet werden, die stabile ID bleibt unverändert',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Alter Name AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        final originalId = tester
            .widget<ContactListTile>(find.byType(ContactListTile))
            .contact
            .id;

        await tester.tap(find.text('Alter Name AG'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact_action_edit')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Neuer Name AG',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        expect(find.text('Neuer Name AG'), findsOneWidget);
        expect(find.text('Alter Name AG'), findsNothing);
        expect(
          tester
              .widget<ContactListTile>(find.byType(ContactListTile))
              .contact
              .id,
          originalId,
        );
      },
    );

    testWidgets('7: Ein unbenutzter Kontakt kann endgültig gelöscht werden', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);

      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Löschbar AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Löschbar AG'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_delete_button')));
      await tester.pumpAndSettle();
      expect(find.text('Kontakt löschen?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('contact_delete_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Löschbar AG'), findsNothing);
      expect(find.byKey(const Key('contacts_empty_state')), findsOneWidget);
    });

    testWidgets(
      '16, 17: PLZ-Auswahl füllt den Ort, Ortsauswahl füllt die PLZ',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        const suggestionKey = Key('postal_suggestion_8340_Hinwil_ZH');

        await tester.enterText(
          find.byKey(const Key('setup_postal_code')),
          '834',
        );
        await tester.pump();
        await tester.ensureVisible(find.byKey(suggestionKey));
        await tester.pump();
        await tester.tap(find.byKey(suggestionKey));
        await tester.pump();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('setup_city')))
              .controller
              ?.text,
          'Hinwil',
        );

        // Beide Felder erst leeren, damit die anschliessende Eingabe von
        // „Hinwil“ (bereits vorhandener Wert aus der PLZ-Auswahl oben) auch
        // wirklich als Änderung erkannt wird und die Vorschlagssuche neu
        // auslöst.
        await tester.enterText(find.byKey(const Key('setup_postal_code')), '');
        await tester.enterText(find.byKey(const Key('setup_city')), '');
        await tester.pump();
        await tester.enterText(find.byKey(const Key('setup_city')), 'Hinwil');
        await tester.pump();
        await tester.ensureVisible(find.byKey(suggestionKey));
        await tester.pump();
        await tester.tap(find.byKey(suggestionKey));
        await tester.pump();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('setup_postal_code')))
              .controller
              ?.text,
          '8340',
        );
      },
    );

    testWidgets(
      '18: Kontakte bleiben nach einem simulierten Neustart erhalten',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Dauerhaft AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();
        expect(find.text('Dauerhaft AG'), findsOneWidget);

        // Neustart simulieren: ein frisches `ContactRepository` aus demselben,
        // noch nicht zurückgesetzten Mock-Speicher laden und eine komplett
        // neue `RootShell`-Instanz aufbauen – wie beim echten App-Neustart.
        final restartedRepository = await ContactRepository.load();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
              contactRepository: restartedRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        expect(find.text('Dauerhaft AG'), findsOneWidget);
      },
    );

    testWidgets('19: Demo-Daten werden nicht mit echten Kontakten vermischt', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Echt AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Echt AG'), findsOneWidget);

      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      expect(find.text('Echt AG'), findsNothing);
      expect(find.text('Sonnenhof Gartenbau AG'), findsOneWidget);

      await tapAddContact(tester);
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Demo-Test AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Demo-Test AG'), findsOneWidget);

      final persisted = (await ContactRepository.load()).readAll();
      expect(persisted.any((c) => c.displayName == 'Demo-Test AG'), isFalse);
      expect(persisted.any((c) => c.displayName == 'Echt AG'), isTrue);
    });

    testWidgets(
      '20: Ein gespeicherter Kunde kann im Rechnungseditor ausgewählt werden',
      (tester) async {
        final customer = Contact(
          isCompany: true,
          companyName: 'Kunde AG',
          street: 'Musterstrasse',
          houseNumber: '1',
          postalCode: '8340',
          city: 'Hinwil',
          isCustomer: true,
        );
        await tester.pumpWidget(
          wrapInvoiceEditor(
            companyProfile: testCompanyProfile(),
            contacts: [customer],
          ),
        );

        await tester.enterText(
          find.byKey(const Key('invoice_customer_search')),
          'Kunde',
        );
        await tester.pump();
        expect(
          find.byKey(const Key('invoice_customer_suggestions')),
          findsOneWidget,
        );
        final suggestion = find.byKey(
          Key('invoice_customer_suggestion_${customer.id}'),
        );
        await tester.ensureVisible(suggestion);
        await tester.pump();
        await tester.tap(suggestion);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('invoice_customer_name')),
              )
              .controller
              ?.text,
          'Kunde AG',
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('invoice_customer_street')),
              )
              .controller
              ?.text,
          'Musterstrasse',
        );
      },
    );

    testWidgets(
      '21: Ein reiner Lieferant erscheint nicht in der Kundenauswahl',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);

        await tapAddContact(tester);
        await tester.tap(find.byKey(const Key('contact_type_customer')));
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Nur Lieferant AG',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Echter Kunde AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('quick_action_create_invoice')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('invoice_customer_search')),
          'Lieferant',
        );
        await tester.pump();
        expect(
          find.byKey(const Key('invoice_customer_suggestions')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const Key('invoice_customer_search')),
          'Echter Kunde',
        );
        await tester.pump();
        expect(find.text('Echter Kunde AG'), findsOneWidget);
      },
    );

    testWidgets('22: Kontaktauswahl verändert keine Rechnungspositionen', (
      tester,
    ) async {
      final customer = Contact(
        isCompany: true,
        companyName: 'Positionstest AG',
        street: 'Teststrasse',
        houseNumber: '9',
        postalCode: '8340',
        city: 'Hinwil',
        isCustomer: true,
      );
      await tester.pumpWidget(
        wrapInvoiceEditor(
          companyProfile: testCompanyProfile(),
          contacts: [customer],
        ),
      );

      await tester.enterText(
        find.byKey(const Key('invoice_item_description_0')),
        'Beratung',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_quantity_0')),
        '3',
      );
      await tester.enterText(
        find.byKey(const Key('invoice_item_unit_price_0')),
        '150',
      );
      final paymentTermBefore = tester
          .widget<TextFormField>(find.byKey(const Key('invoice_payment_term')))
          .controller
          ?.text;
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('invoice_customer_search')),
        'Positionstest',
      );
      await tester.pump();
      final suggestion = find.byKey(
        Key('invoice_customer_suggestion_${customer.id}'),
      );
      await tester.ensureVisible(suggestion);
      await tester.pump();
      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      // Erst sicherstellen, dass die Kontaktauswahl selbst tatsächlich
      // gegriffen hat …
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('invoice_customer_name')),
            )
            .controller
            ?.text,
        'Positionstest AG',
      );
      // … und erst dann, dass sie die Rechnungspositionen unangetastet liess.
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('invoice_item_description_0')),
            )
            .controller
            ?.text,
        'Beratung',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('invoice_item_quantity_0')),
            )
            .controller
            ?.text,
        '3',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('invoice_item_unit_price_0')),
            )
            .controller
            ?.text,
        '150',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('invoice_payment_term')),
            )
            .controller
            ?.text,
        paymentTermBefore,
      );
    });

    testWidgets(
      '23, 24: Termin kann mit einem im Kontakte-Tab erstellten Kontakt verknüpft werden, der Titel bleibt erhalten',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Termin Kontakt AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('appointment_title_field')),
          'Besprechung Kontakte-Tab',
        );
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Termin Kontakt',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('appointment_contact_suggestions')),
          findsOneWidget,
        );
        await tester.tap(find.textContaining('Termin Kontakt AG').last);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('appointment_title_field')),
              )
              .controller
              ?.text,
          'Besprechung Kontakte-Tab',
        );

        await tester.tap(find.byKey(const Key('appointment_save_button')));
        await tester.pumpAndSettle();
        expect(find.text('Besprechung Kontakte-Tab'), findsOneWidget);
      },
    );

    testWidgets(
      '25: Löschen eines bereits verwendeten Kontakts beschädigt keine Dokumente oder Termine',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();

        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Verknüpft AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add_appointment_empty_button')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('appointment_title_field')),
          'Termin mit Verknüpft AG',
        );
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Verknüpft',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Verknüpft AG').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('appointment_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Kontakte').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verknüpft AG'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact_delete_button')));
        await tester.pumpAndSettle();
        expect(find.text('Kontakt archivieren?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('contact_delete_confirm')));
        await tester.pumpAndSettle();

        // Zurück in der Liste: Kontakt ist archiviert, aber weiterhin
        // vorhanden – nichts wurde gelöscht.
        expect(find.text('Verknüpft AG'), findsOneWidget);
        await tester.tap(find.text('Verknüpft AG'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('contact_archived_banner')),
          findsOneWidget,
        );

        // Zurück zur Kontaktliste (Detailansicht ist eine eigene Route, die
        // die untere Navigation verdeckt), dann zurück zu „Heute“.
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Der bestehende Termin zeigt weiterhin unverändert seinen Titel.
        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(find.text('Termin mit Verknüpft AG'), findsOneWidget);
      },
    );

    Future<void> checkContactsNoOverflowAtWidth(
      WidgetTester tester,
      double width,
    ) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      expect(tester.takeException(), isNull, reason: 'Kontaktliste');

      await tester.tap(find.byType(ContactListTile).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Kontaktdetail');

      await tester.tap(find.byKey(const Key('contact_action_edit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Kontaktbearbeitung');
    }

    for (final width in [320.0, 375.0, 390.0, 430.0]) {
      testWidgets(
        '26: Schmales Smartphone-Layout (${width}px) erzeugt keinen Overflow',
        (tester) async {
          await checkContactsNoOverflowAtWidth(tester, width);
        },
      );
    }

    testWidgets('27: Breites Weblayout erzeugt keinen Overflow', (
      tester,
    ) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(ContactListTile).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('contact_action_edit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // Kontakte-Abschluss: Heute-Schnellaktion, Feld-Kontrast, IBAN-Sichtbarkeit,
  // Detailseite, Rechnungs-/Terminverknüpfung von der Detailseite aus.
  // ---------------------------------------------------------------------

  group('Kontakte-Abschluss', () {
    Future<void> openContactsTab(WidgetTester tester) async {
      await tester.tap(find.text('Kontakte').last);
      await tester.pumpAndSettle();
    }

    Future<void> tapAddContact(WidgetTester tester) async {
      final emptyButton = find.byKey(const Key('contacts_empty_add_button'));
      if (emptyButton.evaluate().isNotEmpty) {
        await tester.tap(emptyButton);
      } else {
        await tester.tap(find.byKey(const Key('contacts_add_button')));
      }
      await tester.pumpAndSettle();
    }

    Future<void> fillContactAddress(
      WidgetTester tester, {
      String street = 'Musterstrasse',
      String houseNumber = '1',
      String postalCode = '8340',
      String city = 'Hinwil',
    }) async {
      await tester.enterText(find.byKey(const Key('contact_street')), street);
      await tester.enterText(
        find.byKey(const Key('contact_house_number')),
        houseNumber,
      );
      await tester.enterText(
        find.byKey(const Key('setup_postal_code')),
        postalCode,
      );
      await tester.enterText(find.byKey(const Key('setup_city')), city);
    }

    testWidgets('1-5: Heute-Schnellaktion „Kontakt hinzufügen“ ist kein „Bald '
        'verfügbar“ mehr, öffnet denselben Editor, Abbrechen erstellt nichts, '
        'Speichern erstellt genau einen Kontakt sofort im Kontakte-Tab', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();

      // 1: kein „Bald verfügbar“ mehr bei „Kontakt hinzufügen“, die
      // beiden noch nicht umgesetzten Aktionen bleiben ehrlich markiert.
      expect(
        find.descendant(
          of: find.byKey(const Key('quick_action_add_contact')),
          matching: find.text('Bald verfügbar'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('quick_action_create_offer')),
          matching: find.text('Bald verfügbar'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('quick_action_create_contract')),
          matching: find.text('Bald verfügbar'),
        ),
        findsOneWidget,
      );

      // Abbrechen: kein Kontakt entsteht.
      await tester.tap(find.byKey(const Key('quick_action_add_contact')));
      await tester.pumpAndSettle();
      // 2: derselbe Kontakteditor wie im Kontakte-Tab (identische Keys).
      expect(find.byKey(const Key('contact_save_button')), findsOneWidget);
      expect(
        find.byKey(const Key('contact_is_company_selector')),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      // 3: nichts wurde erstellt.
      expect(find.byKey(const Key('contacts_empty_state')), findsOneWidget);

      // Speichern: genau ein Kontakt, sofort im Kontakte-Tab sichtbar.
      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_action_add_contact')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Von Heute erstellt AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await openContactsTab(tester);
      // 4 + 5: genau ein Kontakt, direkt sichtbar.
      expect(find.text('Von Heute erstellt AG'), findsOneWidget);
      expect(find.byType(ContactListTile), findsOneWidget);
    });

    testWidgets(
      '6: Kontaktfelder haben bereits ohne Fokus einen sichtbaren Rahmen '
      'und Hintergrund',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        final decorationTheme = Theme.of(
          tester.element(find.byKey(const Key('contact_company_name'))),
        ).inputDecorationTheme;

        expect(decorationTheme.filled, isTrue);
        expect(decorationTheme.fillColor, isNot(Colors.white));
        expect(decorationTheme.fillColor, isNot(AppColors.background));

        final enabledBorder =
            decorationTheme.enabledBorder as OutlineInputBorder;
        expect(enabledBorder.borderSide.width, greaterThan(0));
        // Der Feldrahmen muss klarer erkennbar sein als der dezente
        // Kartenrahmen – sonst wirkt ein Feld wie eine reine Fläche.
        expect(enabledBorder.borderSide.color, isNot(AppColors.border));
      },
    );

    testWidgets(
      '7: Fokussierte Kontaktfelder haben einen deutlich blauen Rahmen',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        final decorationTheme = Theme.of(
          tester.element(find.byKey(const Key('contact_company_name'))),
        ).inputDecorationTheme;
        final focusedBorder =
            decorationTheme.focusedBorder as OutlineInputBorder;
        final enabledBorder =
            decorationTheme.enabledBorder as OutlineInputBorder;

        expect(focusedBorder.borderSide.color, AppColors.sky600);
        expect(
          focusedBorder.borderSide.width,
          greaterThan(enabledBorder.borderSide.width),
        );
      },
    );

    testWidgets(
      '8: Fehlerhafte Kontaktfelder zeigen einen roten Rahmen und eine '
      'deutsche Fehlermeldung',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        final decorationTheme = Theme.of(
          tester.element(find.byKey(const Key('contact_company_name'))),
        ).inputDecorationTheme;
        final errorBorder = decorationTheme.errorBorder as OutlineInputBorder;
        expect(errorBorder.borderSide.color, AppColors.danger);

        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();
        expect(find.text('Bitte Firmenname eingeben'), findsOneWidget);
      },
    );

    testWidgets(
      '11: Eine bestehende IBAN geht beim Bearbeiten nicht unbemerkt verloren',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);

        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'IBAN Bewahren AG',
        );
        await fillContactAddress(tester);
        await tester.enterText(
          find.byKey(const Key('contact_iban')),
          _validIban,
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('IBAN Bewahren AG'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact_action_edit')));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('contact_iban')))
              .controller
              ?.text,
          'CH93 0076 2011 6238 5295 7',
        );

        // Kurzzeitig auf „nur Kunde“ wechseln (Feld verschwindet) und
        // wieder zurück zu Lieferant – der Wert darf dabei nicht verloren
        // gehen.
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('contact_iban')), findsNothing);
        await tester.tap(find.byKey(const Key('contact_type_supplier')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('contact_iban')))
              .controller
              ?.text,
          'CH93 0076 2011 6238 5295 7',
        );

        // Eine unabhängige Änderung speichern – IBAN bleibt erhalten.
        await tester.enterText(
          find.byKey(const Key('contact_note')),
          'Aktualisiert',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('IBAN Bewahren AG'));
        await tester.pumpAndSettle();
        expect(find.text('CH93 0076 2011 6238 5295 7'), findsOneWidget);
      },
    );

    testWidgets('15: Detailseite zeigt Name und Kontaktart eindeutig', (
      tester,
    ) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);
      await tester.tap(find.byKey(const Key('contact_type_supplier')));
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Klarer Kontakt AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Klarer Kontakt AG'));
      await tester.pumpAndSettle();

      expect(find.text('Klarer Kontakt AG'), findsWidgets);
      expect(find.text('Kunde'), findsOneWidget);
      expect(find.text('Lieferant'), findsOneWidget);
    });

    testWidgets(
      '16: Leere Informationsbereiche werden auf der Detailseite nicht '
      'angezeigt',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Minimal AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Minimal AG'));
        await tester.pumpAndSettle();

        expect(find.text('Adresse'), findsOneWidget);
        expect(find.text('Kontaktdaten'), findsNothing);
        expect(find.text('Zahlungsangaben'), findsNothing);
        expect(find.text('Notiz'), findsNothing);
      },
    );

    testWidgets(
      '17: „Rechnung erstellen“ auf der Detailseite übergibt den richtigen '
      'Kontakt',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Rechnungskontakt AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Rechnungskontakt AG'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('contact_action_create_invoice')),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('invoice_customer_name')),
              )
              .controller
              ?.text,
          'Rechnungskontakt AG',
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('invoice_customer_street')),
              )
              .controller
              ?.text,
          'Musterstrasse',
        );
      },
    );

    testWidgets('18, 19: „Termin erstellen“ auf der Detailseite verknüpft den '
        'richtigen Kontakt, ohne den Titel zu überschreiben', (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Terminkontakt AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terminkontakt AG'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('contact_action_create_appointment')),
      );
      await tester.pumpAndSettle();

      // Titel bleibt leer/manuell – wird nicht durch den Kontaktnamen
      // ersetzt; der Kontakt ist aber bereits erkennbar verknüpft.
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('appointment_title_field')),
            )
            .controller
            ?.text,
        '',
      );
      expect(find.textContaining('verknüpft'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('appointment_title_field')),
        'Eigener Titel',
      );
      await tester.tap(find.byKey(const Key('appointment_save_button')));
      await tester.pumpAndSettle();

      // Zurück zur Kontaktliste (der Termin-Dialog liegt über der
      // Detailseite, die untere Navigation ist dort nicht sichtbar).
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();
      expect(find.text('Eigener Titel'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // Fix: Kontakte-Tab und die Kontaktsuche im Termin-Dialog auf „Heute“
  // müssen dieselbe zentrale Kontaktquelle verwenden (siehe
  // `RootShell._contacts`/`_demoContacts`) – vorher pflegte „Heute“ eine
  // eigene, unabhängige Demo-Kontaktliste, wodurch neu erstellte Kontakte im
  // Termin-Dialog nicht auffindbar waren.
  // ---------------------------------------------------------------------

  group('Kontaktsuche im Termin-Dialog nutzt die zentrale Kontaktquelle', () {
    Future<void> openContactsTab(WidgetTester tester) async {
      await tester.tap(find.text('Kontakte').last);
      await tester.pumpAndSettle();
    }

    Future<void> tapAddContact(WidgetTester tester) async {
      final emptyButton = find.byKey(const Key('contacts_empty_add_button'));
      if (emptyButton.evaluate().isNotEmpty) {
        await tester.tap(emptyButton);
      } else {
        await tester.tap(find.byKey(const Key('contacts_add_button')));
      }
      await tester.pumpAndSettle();
    }

    Future<void> fillContactAddress(
      WidgetTester tester, {
      String street = 'Musterstrasse',
      String houseNumber = '1',
      String postalCode = '8340',
      String city = 'Hinwil',
    }) async {
      await tester.enterText(find.byKey(const Key('contact_street')), street);
      await tester.enterText(
        find.byKey(const Key('contact_house_number')),
        houseNumber,
      );
      await tester.enterText(
        find.byKey(const Key('setup_postal_code')),
        postalCode,
      );
      await tester.enterText(find.byKey(const Key('setup_city')), city);
    }

    /// Öffnet den Termin-Dialog auf „Heute“ – nutzt je nach Vorzustand den
    /// Leerzustand- oder den Inline-Button (Demo-Modus hat bereits Termine).
    Future<void> openAppointmentDialog(WidgetTester tester) async {
      final emptyButton = find.byKey(const Key('add_appointment_empty_button'));
      if (emptyButton.evaluate().isNotEmpty) {
        await tester.tap(emptyButton);
      } else {
        await tester.tap(
          find.byKey(const Key('add_appointment_inline_button')),
        );
      }
      await tester.pumpAndSettle();
    }

    testWidgets(
      '1: Ein neuer Kontakt wird gespeichert und erscheint im zentralen '
      'Kontakt-State (Kontakte-Tab)',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Zentral Sichtbar AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        expect(find.text('Zentral Sichtbar AG'), findsOneWidget);
      },
    );

    testWidgets(
      '2, 4, 5: Neu gespeicherter Firmenkontakt ist im Termin-Dialog über '
      'einen Teil des Namens und unabhängig von Gross-/Kleinschreibung '
      'suchbar',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Frisch Erstellt AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await openAppointmentDialog(tester);

        // Teilname, kleingeschrieben.
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'erstellt',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Frisch Erstellt AG'), findsWidgets);

        // Teilname, grossgeschrieben.
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'FRISCH',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Frisch Erstellt AG'), findsWidgets);
      },
    );

    testWidgets(
      '3, 4: Neu gespeicherte Privatperson ist im Termin-Dialog über einen '
      'Teil des Namens suchbar',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('contact_is_company_selector')),
            matching: find.text('Privatperson'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('contact_first_name')),
          'Petra',
        );
        await tester.enterText(
          find.byKey(const Key('contact_last_name')),
          'Beispiel',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await openAppointmentDialog(tester);
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Beispiel',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Petra Beispiel'), findsWidgets);
      },
    );

    testWidgets(
      '6, 7, 8: Kontakt kann ausgewählt werden, der Termin speichert die '
      'stabile Kontakt-ID, der eigene Termintitel bleibt erhalten',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Stabile ID AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await openAppointmentDialog(tester);
        await tester.enterText(
          find.byKey(const Key('appointment_title_field')),
          'Eigener Termintitel',
        );
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Stabile ID',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Stabile ID AG').last);
        await tester.pumpAndSettle();

        // 8: Titel bleibt unverändert.
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const Key('appointment_title_field')),
              )
              .controller
              ?.text,
          'Eigener Termintitel',
        );
        // 6: Auswahl hat gegriffen.
        expect(find.textContaining('verknüpft'), findsOneWidget);

        await tester.tap(find.byKey(const Key('appointment_save_button')));
        await tester.pumpAndSettle();
        expect(find.text('Eigener Termintitel'), findsOneWidget);

        // 7: Der Termin hält die stabile Kontakt-ID, nicht nur den Namen –
        // nachgewiesen darüber, dass der verknüpfte Kontakt beim Löschen
        // jetzt als „verwendet“ erkannt und automatisch archiviert statt
        // hart gelöscht wird (`RootShell._isContactInUse` prüft nur über
        // `Appointment.contactId`, nie über den Namen).
        await openContactsTab(tester);
        await tester.tap(find.text('Stabile ID AG'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact_delete_button')));
        await tester.pumpAndSettle();
        expect(find.text('Kontakt archivieren?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('contact_delete_confirm')));
        await tester.pumpAndSettle();
        expect(find.text('Stabile ID AG'), findsOneWidget);
      },
    );

    testWidgets(
      '10: Nach dem Bearbeiten eines Kontakts verwendet die Terminsuche die '
      'aktuellen Daten',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Alter Suchname AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Alter Suchname AG'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact_action_edit')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Neuer Suchname AG',
        );
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await openAppointmentDialog(tester);
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Alter Suchname',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Alter Suchname AG'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Neuer Suchname',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Neuer Suchname AG'), findsWidgets);
      },
    );

    testWidgets('11: Nach dem Löschen erscheint der Kontakt nicht mehr in der '
        'Terminsuche', (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell());
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Zu Löschen AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zu Löschen AG'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_delete_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact_delete_confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();
      await openAppointmentDialog(tester);
      await tester.enterText(
        find.byKey(const Key('appointment_contact_search')),
        'Zu Löschen',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Zu Löschen AG'), findsNothing);
    });

    testWidgets('12: Demo-Kontakte und selbst erstellte Kontakte stammen im '
        'Termin-Dialog nicht aus getrennten Listen', (tester) async {
      useTallTestViewport(tester);
      await tester.pumpWidget(wrapRootShell(isDemoMode: true));
      await tester.pumpAndSettle();
      await openContactsTab(tester);
      await tapAddContact(tester);
      await tester.enterText(
        find.byKey(const Key('contact_company_name')),
        'Demo Neu Erstellt AG',
      );
      await fillContactAddress(tester);
      await tester.tap(find.byKey(const Key('contact_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heute').last);
      await tester.pumpAndSettle();
      await openAppointmentDialog(tester);

      // Der neu erstellte Demo-Kontakt ist auffindbar …
      await tester.enterText(
        find.byKey(const Key('appointment_contact_search')),
        'Demo Neu Erstellt',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Demo Neu Erstellt AG'), findsWidgets);

      // … genau wie ein vorbereiteter Demo-Kontakt aus derselben Liste
      // (`RootShell._buildDemoContacts`) – beide kommen aus derselben
      // Quelle, nicht aus zwei getrennten.
      await tester.enterText(
        find.byKey(const Key('appointment_contact_search')),
        'Fischer',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Laura Fischer'), findsWidgets);
    });

    testWidgets(
      '13: Nach einem simulierten Neustart bleibt ein neuer Kontakt im '
      'Termin-Dialog suchbar',
      (tester) async {
        useTallTestViewport(tester);
        await tester.pumpWidget(wrapRootShell());
        await tester.pumpAndSettle();
        await openContactsTab(tester);
        await tapAddContact(tester);
        await tester.enterText(
          find.byKey(const Key('contact_company_name')),
          'Neustart AG',
        );
        await fillContactAddress(tester);
        await tester.tap(find.byKey(const Key('contact_save_button')));
        await tester.pumpAndSettle();

        final restartedRepository = await ContactRepository.load();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
              contactRepository: restartedRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        await openAppointmentDialog(tester);
        await tester.enterText(
          find.byKey(const Key('appointment_contact_search')),
          'Neustart',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Neustart AG'), findsWidgets);
      },
    );
  });
}
