import 'invoice_customer.dart';
import 'invoice_line_item.dart';

/// Fachlicher Status einer Rechnung. „Überfällig“ ist bewusst KEIN eigener
/// Status, sondern wird aus `status == open` und dem Fälligkeitsdatum
/// abgeleitet (siehe [InvoiceDraft.isOverdue]) – so kann es nie einen
/// widersprüchlichen Zustand wie „überfällig, aber bezahlt“ geben.
enum InvoiceStatus { draft, open, paid }

/// Ein Rechnungsentwurf bzw. eine Rechnung. Wird vorerst nur im lokalen
/// App-Zustand gehalten (siehe ROADMAP.md für dauerhafte lokale Speicherung
/// und Backend).
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

  /// Fachlicher Status. Jede neu gespeicherte Rechnung ist zunächst ein
  /// `draft` (Entwurf) – Entwürfe zählen nirgends als offene Forderung und
  /// niemals als Umsatz. Der Wechsel zu `open` („Rechnung stellen“) und zu
  /// `paid` („Als bezahlt markieren“) erfolgt ausschliesslich über eine
  /// bewusste Nutzeraktion im Dokumente-Tab – es wird nie automatisch eine
  /// Zahlung erfunden oder erkannt (siehe ROADMAP.md: eine echte
  /// Bankanbindung könnte das später ergänzen).
  InvoiceStatus status = InvoiceStatus.draft;

  /// Zeitpunkt, zu dem die Rechnung als bezahlt markiert wurde. Massgeblich
  /// dafür, in welchem Monat sie zum „Umsatz diesen Monat“ zählt. `null`,
  /// solange die Rechnung nicht bezahlt ist.
  DateTime? paidAt;

  DateTime get dueDate => invoiceDate.add(Duration(days: paymentTermDays));

  /// Eine gestellte (nicht mehr im Entwurf befindliche), noch nicht bezahlte
  /// Rechnung, deren Fälligkeitsdatum bereits verstrichen ist. Bewusst aus
  /// Status und Datum abgeleitet statt als eigener Speicherstatus, damit nie
  /// ein Widerspruch wie „überfällig und bezahlt“ entstehen kann.
  bool get isOverdue =>
      status == InvoiceStatus.open && dueDate.isBefore(DateTime.now());

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
