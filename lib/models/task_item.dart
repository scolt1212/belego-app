import '../utils/id_generator.dart';

/// Optionale Kategorie einer Aufgabe.
enum TaskCategory { business, private }

/// Eine Aufgabe auf der Startseite. Wird vorerst nur im lokalen App-Zustand
/// gehalten, siehe ROADMAP.md für dauerhafte Speicherung.
class TaskItem {
  TaskItem({
    String? id,
    required this.title,
    this.dueDate,
    this.isDone = false,
    this.category,
  }) : id = id ?? IdGenerator.next('aufgabe');

  final String id;
  String title;
  DateTime? dueDate;
  bool isDone;
  TaskCategory? category;
}
