/// Eine offene Forderung (Rechnung, die noch bezahlt werden muss).
class Forderung {
  final String kontaktName;
  final double betrag;
  final DateTime faelligkeitsdatum;
  final String belegNummer;

  const Forderung({
    required this.kontaktName,
    required this.betrag,
    required this.faelligkeitsdatum,
    required this.belegNummer,
  });

  bool get istUeberfaellig => faelligkeitsdatum.isBefore(DateTime.now());

  int get tageDifferenz => faelligkeitsdatum.difference(DateTime.now()).inDays;
}
