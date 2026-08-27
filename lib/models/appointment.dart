import '../utils/id_generator.dart';

/// Kategorie eines Termins – bestimmt die Akzentfarbe in Kalender und Liste
/// (siehe `AppColors.businessBlue` für Geschäftlich, `AppColors.privateOrange`
/// für Privat).
enum AppointmentCategory { business, private }

/// Ein Termin im Kalender der Startseite. Wird vorerst nur im lokalen
/// App-Zustand gehalten, siehe ROADMAP.md für dauerhafte Speicherung. Die ID
/// ist bereits jetzt eindeutig, damit eine spätere Speicherung ohne
/// Datenmigration möglich ist.
class Appointment {
  Appointment({
    String? id,
    required this.title,
    required this.start,
    required this.end,
    this.note = '',
    this.category = AppointmentCategory.business,
    this.contactId,
  }) : id = id ?? IdGenerator.next('termin');

  final String id;
  String title;
  DateTime start;
  DateTime end;
  String note;
  AppointmentCategory category;

  /// Verweist auf die stabile ID eines [Contact], falls beim Erstellen ein
  /// Kontakt ausgewählt wurde. Rein optional – ein Termin funktioniert auch
  /// ohne verknüpften Kontakt.
  String? contactId;

  /// Kalendertag dieses Termins (ohne Uhrzeit), für den Wochenkalender.
  DateTime get date => DateTime(start.year, start.month, start.day);

  bool isOnDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;
}

/// Montag der Woche, in der [day] liegt (Schweizer Wochenstart).
DateTime startOfWeek(DateTime day) {
  final normalized = DateTime(day.year, day.month, day.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

/// [day] um [months] Monate verschoben (kann negativ sein), auf den 1. Tag
/// des Zielmonats normalisiert – für die Monatsnavigation im Kalender.
DateTime addMonths(DateTime day, int months) {
  final totalMonths = day.year * 12 + (day.month - 1) + months;
  return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1);
}
