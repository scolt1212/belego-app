/// Erzeugt einfache, eindeutige lokale IDs für Termine und Aufgaben, solange
/// keine dauerhafte Speicherung mit serverseitig vergebenen IDs existiert
/// (siehe ROADMAP.md).
class IdGenerator {
  IdGenerator._();

  static int _counter = 0;

  static String next(String prefix) {
    _counter += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
