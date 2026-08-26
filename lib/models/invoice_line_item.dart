/// Auswählbare Mengeneinheiten für Rechnungspositionen.
const List<String> invoiceUnits = [
  'Stück',
  'Std.',
  'Tag',
  'pauschal',
  'm',
  'm²',
  'kg',
];

/// Gängige Schweizer MWST-Sätze zur Auswahl (Firmeneinrichtung und
/// Rechnungspositionen). Der Satz bleibt jederzeit änderbar; es findet
/// keine steuerrechtliche Automatisierung statt.
const List<double> vatRateOptions = [8.1, 3.8, 2.6, 0.0];

/// Eine einzelne Position einer Rechnung.
///
/// Geldbeträge werden als ganzzahlige Rappen gehalten (siehe
/// `lib/utils/money.dart`), um Gleitkomma-Rundungsfehler zu vermeiden.
class InvoiceLineItem {
  InvoiceLineItem({
    this.description = '',
    this.detail = '',
    this.quantity = 1,
    this.unit = 'Stück',
    this.unitPriceRappen = 0,
    this.vatRate = 8.1,
  });

  String description;
  String detail;
  double quantity;
  String unit;
  int unitPriceRappen;

  /// MWST-Satz dieser Position; wird nur verrechnet, wenn die Firma
  /// MWST-pflichtig ist.
  double vatRate;

  int get netAmountRappen => (quantity * unitPriceRappen).round();

  int vatAmountRappen({required bool companyIsVatLiable}) {
    if (!companyIsVatLiable) return 0;
    return (netAmountRappen * vatRate / 100).round();
  }

  int totalAmountRappen({required bool companyIsVatLiable}) =>
      netAmountRappen + vatAmountRappen(companyIsVatLiable: companyIsVatLiable);
}
