import 'invoice_customer.dart';
import 'invoice_line_item.dart';

/// Ein Rechnungsentwurf. Wird vorerst nur im lokalen App-Zustand gehalten
/// (siehe ROADMAP.md für dauerhafte lokale Speicherung und Backend).
class InvoiceDraft {
  InvoiceDraft({
    this.invoiceNumber,
    required this.invoiceDate,
    this.paymentTermDays = 30,
  });

  /// Vorläufig nachvollziehbar erzeugte Nummer (Jahr + laufende lokale
  /// Nummer), z.B. „RE-2026-0001“. `null`, solange die Rechnung noch nie
  /// gespeichert wurde – die Nummer wird erst beim ersten Speichern fest
  /// vergeben, damit ein geöffnetes und wieder verworfenes leeres Formular
  /// keine Nummer verbraucht. Danach unveränderlich, auch beim erneuten
  /// Bearbeiten. Eine dauerhafte, pro Firma eindeutige Nummernvergabe folgt
  /// später (siehe ROADMAP.md).
  String? invoiceNumber;

  DateTime invoiceDate;
  int paymentTermDays;

  String title = '';
  String introText = '';

  InvoiceCustomer customer = InvoiceCustomer();
  List<InvoiceLineItem> items = [InvoiceLineItem()];

  DateTime get dueDate => invoiceDate.add(Duration(days: paymentTermDays));

  int subtotalRappen() =>
      items.fold(0, (sum, item) => sum + item.netAmountRappen);

  int vatTotalRappen({required bool companyIsVatLiable}) => items.fold(
    0,
    (sum, item) =>
        sum + item.vatAmountRappen(companyIsVatLiable: companyIsVatLiable),
  );

  int totalRappen({required bool companyIsVatLiable}) =>
      subtotalRappen() + vatTotalRappen(companyIsVatLiable: companyIsVatLiable);
}
