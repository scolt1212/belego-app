import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/task_item.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validators.dart';

/// Kompakter Aufgabenbereich: hinzufügen, erledigen/wieder öffnen, löschen.
class TasksSection extends StatelessWidget {
  const TasksSection({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onAdd;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;

  Future<void> _openAddDialog(BuildContext context) async {
    final result = await showDialog<TaskItem>(
      context: context,
      builder: (_) => const _TaskEditorDialog(),
    );
    if (result != null) onAdd(result);
  }

  @override
  Widget build(BuildContext context) {
    final openTasks = tasks.where((t) => !t.isDone).toList();
    final doneTasks = tasks.where((t) => t.isDone).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: AppColors.sky600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Aufgaben',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (openTasks.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Heute ist alles erledigt.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
                for (var i = 0; i < openTasks.length; i++) ...[
                  if (i > 0) const Divider(height: 17, color: AppColors.border),
                  _TaskRow(
                    task: openTasks[i],
                    onToggle: () => onToggle(openTasks[i].id),
                    onDelete: () => onDelete(openTasks[i].id),
                  ),
                ],
                const SizedBox(height: 4),
              ],
              if (doneTasks.isNotEmpty) ...[
                const Divider(height: 17, color: AppColors.border),
                for (var i = 0; i < doneTasks.length; i++) ...[
                  if (i > 0) const Divider(height: 17, color: AppColors.border),
                  _TaskRow(
                    task: doneTasks[i],
                    onToggle: () => onToggle(doneTasks[i].id),
                    onDelete: () => onDelete(doneTasks[i].id),
                  ),
                ],
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('add_task_empty_button'),
                  onPressed: () => _openAddDialog(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Aufgabe hinzufügen')),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  static Color? _categoryColor(TaskCategory? category) {
    switch (category) {
      case TaskCategory.business:
        return AppColors.businessBlue;
      case TaskCategory.private:
        return AppColors.privateOrange;
      case null:
        return null;
    }
  }

  static String _categoryLabel(TaskCategory? category) {
    switch (category) {
      case TaskCategory.business:
        return 'Geschäftlich';
      case TaskCategory.private:
        return 'Privat';
      case null:
        return 'Keine Kategorie';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final categoryColor = _categoryColor(task.category) ?? AppColors.draftGrey;
    return Semantics(
      label:
          '${task.isDone ? 'Erledigt' : 'Offen'}, ${_categoryLabel(task.category)}',
      child: Padding(
        key: Key('task_${task.id}'),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: AnimatedOpacity(
          opacity: task.isDone ? 0.55 : 1,
          duration: duration,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: task.isDone
                    ? '${task.title}, erledigt, antippen zum Wiedereröffnen'
                    : '${task.title}, offen, antippen zum Abhaken',
                child: Checkbox(
                  key: Key('task_checkbox_${task.id}'),
                  value: task.isDone,
                  activeColor: AppColors.sky600,
                  onChanged: (_) => onToggle(),
                ),
              ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: task.isDone
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  child: Text(
                    task.dueDate == null
                        ? task.title
                        : '${task.title} · ${_dateFormat.format(task.dueDate!)}',
                  ),
                ),
              ),
              IconButton(
                key: Key('task_delete_${task.id}'),
                tooltip: 'Aufgabe löschen',
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog();

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _dueDate;
  TaskCategory? _category;

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fälligkeitsdatum wählen',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TaskItem(
        title: _titleController.text.trim(),
        dueDate: _dueDate,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aufgabe hinzufügen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('task_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  hintText: 'z. B. Rechnung Fusi AG senden',
                ),
                validator: (v) => Validators.required(
                  v,
                  message: 'Bitte einen Titel eingeben',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('task_due_date_picker'),
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fälligkeitsdatum (optional)',
                    suffixIcon: _dueDate == null
                        ? const Icon(Icons.calendar_today_outlined, size: 18)
                        : IconButton(
                            tooltip: 'Datum entfernen',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                  ),
                  child: Text(
                    _dueDate == null
                        ? 'Kein Datum'
                        : _dateFormat.format(_dueDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    key: const Key('task_category_none'),
                    label: const Text('Keine'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  ChoiceChip(
                    key: const Key('task_category_business'),
                    label: const Text('Geschäftlich'),
                    selected: _category == TaskCategory.business,
                    onSelected: (_) =>
                        setState(() => _category = TaskCategory.business),
                  ),
                  ChoiceChip(
                    key: const Key('task_category_private'),
                    label: const Text('Privat'),
                    selected: _category == TaskCategory.private,
                    onSelected: (_) =>
                        setState(() => _category = TaskCategory.private),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          key: const Key('task_save_button'),
          onPressed: _submit,
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
