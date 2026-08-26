import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:belego/main.dart';
import 'package:belego/models/company_profile.dart';
import 'package:belego/models/invoice_draft.dart';
import 'package:belego/screens/documents/invoice/invoice_editor_screen.dart';
import 'package:belego/screens/onboarding/company_setup_screen.dart';
import 'package:belego/screens/onboarding/widgets/company_logo_section.dart';
import 'package:belego/screens/root_shell.dart';
import 'package:belego/services/postal_code_service.dart';
import 'package:belego/theme/app_theme.dart';
import 'package:belego/utils/iban.dart';
import 'package:belego/utils/logo_validation.dart';
import 'package:belego/utils/money.dart';
import 'package:belego/utils/swiss_phone_number.dart';
import 'package:belego/utils/swiss_vat_number.dart';

// Kleinstmögliches gültiges PNG (1×1, transparent) – eindeutig als
// Test-/Platzhalterbild erkennbar, keine echten Bilddaten.
final Uint8List _testPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

// Offizielle Beispiel-IBAN aus der ISO-13616-/SEPA-Dokumentation, keine
// echte Bankverbindung. Erfüllt absichtlich die Modulo-97-Prüfsumme.
const _validIban = 'CH93 0076 2011 6238 5295 7';
final _swissDateFormat = DateFormat('dd.MM.yyyy');

void main() {
  late PostalCodeService postalCodeService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final entries = await PostalCodeService.loadEntriesFromAsset();
    postalCodeService = PostalCodeService(entries: entries);
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

  Widget wrapInvoiceEditor({
    required CompanyProfile companyProfile,
    InvoiceDraft? existingDraft,
    ValueChanged<InvoiceDraft>? onSaveDraft,
    String Function()? allocateInvoiceNumber,
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
      await tester.pumpWidget(BelegoApp(postalCodeService: postalCodeService));

      expect(find.text('belego'), findsOneWidget);
      expect(find.text('Kostenlos registrieren'), findsOneWidget);
      expect(find.text('Anmelden'), findsOneWidget);
      expect(find.text('Demo ansehen'), findsOneWidget);
    });

    testWidgets('Demo-Modus zeigt Beispieldaten, Demo verlassen führt zurück', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(BelegoApp(postalCodeService: postalCodeService));

      await tester.tap(find.text('Demo ansehen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Demo-Modus'), findsOneWidget);
      expect(find.text('Müller Bau GmbH'), findsOneWidget);

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
      await tester.pumpWidget(BelegoApp(postalCodeService: postalCodeService));
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
      expect(find.text('Noch keine offenen Forderungen'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // Rechnungseditor
  // ---------------------------------------------------------------------

  group('Rechnungseditor', () {
    testWidgets(
      '"Rechnung erstellen" öffnet den Editor, Rechnungsnummer ist nicht editierbar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('empty_today_create_invoice')));
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
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
            ),
          ),
        );

        // 1) Editor öffnen, etwas eintippen, dann verwerfen -> keine Nummer verbraucht.
        await tester.tap(find.byKey(const Key('empty_today_create_invoice')));
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
        expect(find.text('Noch keine offenen Forderungen'), findsOneWidget);

        // 2) Erste echte Rechnung speichern -> erhält RE-2026-0001.
        await tester.tap(find.byKey(const Key('empty_today_create_invoice')));
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
        await tester.tap(find.byKey(const Key('empty_today_create_invoice')));
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
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: RootShell(
              isDemoMode: false,
              companyProfile: testCompanyProfile(),
              postalCodeService: postalCodeService,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('empty_today_create_invoice')));
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

        // Heute bleibt weiterhin leer – ein Entwurf ist keine offene Forderung.
        await tester.tap(find.text('Heute').last);
        await tester.pumpAndSettle();
        expect(find.text('Noch keine offenen Forderungen'), findsOneWidget);

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
      await tester.pumpWidget(wrapSetupScreen());
      await completeStep1(tester);
      await tester.enterText(find.byKey(const Key('setup_iban')), _validIban);
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('setup_primary_action')));
      await tester.pumpAndSettle();

      expect(find.text('Noch keine offenen Forderungen'), findsOneWidget);
      expect(
        find.text('Erstelle deine erste Rechnung oder Offerte.'),
        findsOneWidget,
      );
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
}
