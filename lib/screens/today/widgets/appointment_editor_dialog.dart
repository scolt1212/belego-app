import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/appointment.dart';
import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validators.dart';

/// Öffnet den Termin-Dialog zum Hinzufügen (ohne [existing]) oder Bearbeiten
/// (mit [existing]) und liefert den gespeicherten Termin zurück, oder `null`
/// bei Abbruch. [contacts] sind die aktuell bekannten Kontakte für die
/// optionale Kontaktsuche. [initialContact] verknüpft einen NEUEN Termin
/// direkt mit diesem Kontakt (z.B. „Termin erstellen“ auf der
/// Kontakt-Detailseite), ohne den Titel vorzubelegen; wird bei [existing]
/// ignoriert.
Future<Appointment?> showAppointmentEditorDialog(
  BuildContext context, {
  required DateTime initialDate,
  Appointment? existing,
  List<Contact> contacts = const [],
  Contact? initialContact,
}) {
  return showDialog<Appointment>(
    context: context,
    builder: (_) => AppointmentEditorDialog(
      initialDate: initialDate,
      existing: existing,
      contacts: contacts,
      initialContact: initialContact,
    ),
  );
}

/// Dialog zum Erfassen oder Bearbeiten eines Termins. Titel, Datum und
/// Startzeit sind Pflicht; die Endzeit darf nicht vor der Startzeit liegen.
/// Enthält eine optionale Kontaktsuche, die einen Termin mit einem bereits
/// gespeicherten Kontakt verknüpft, ohne den Titel zu verändern.
class AppointmentEditorDialog extends StatefulWidget {
  const AppointmentEditorDialog({
    super.key,
    required this.initialDate,
    this.existing,
    this.contacts = const [],
    this.initialContact,
  });

  final DateTime initialDate;
  final Appointment? existing;
  final List<Contact> contacts;

  /// Verknüpft einen NEUEN Termin direkt mit diesem Kontakt. Wird bei
  /// [existing] ignoriert und überschreibt nie den Titel.
  final Contact? initialContact;

  @override
  State<AppointmentEditorDialog> createState() =>
      _AppointmentEditorDialogState();
}

class _AppointmentEditorDialogState extends State<AppointmentEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _contactSearchController;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late AppointmentCategory _category;
  String? _selectedContactId;
  List<Contact> _suggestions = [];
  bool _isApplyingContactSelection = false;

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _date = existing?.date ?? _normalizedDate(widget.initialDate);
    _startTime = existing != null
        ? TimeOfDay.fromDateTime(existing.start)
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = existing != null
        ? TimeOfDay.fromDateTime(existing.end)
        : const TimeOfDay(hour: 10, minute: 0);
    _category = existing?.category ?? AppointmentCategory.business;
    _selectedContactId = existing?.contactId ?? widget.initialContact?.id;
    final linkedContact =
        _findContact(_selectedContactId) ??
        (existing == null ? widget.initialContact : null);
    _contactSearchController = TextEditingController(
      text: linkedContact?.displayName ?? '',
    );
  }

  Contact? _findContact(String? id) {
    if (id == null) return null;
    for (final contact in widget.contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  static DateTime _normalizedDate(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Datum wählen',
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Ob [_date] vor dem heutigen Tag liegt – vergangene Termine dürfen
  /// betrachtet, aber beim Neuanlegen nur mit einer deutlichen Warnung
  /// erstellt werden.
  bool get _isPastDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _date.isBefore(today);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Startzeit wählen',
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Endzeit wählen',
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  void _handleContactSearchChanged(String query) {
    if (_isApplyingContactSelection) return;
    final trimmed = query.trim().toLowerCase();
    setState(() {
      _selectedContactId = null;
      _suggestions = trimmed.isEmpty
          ? const []
          : widget.contacts
                .where((c) => c.displayName.toLowerCase().contains(trimmed))
                .toList();
    });
  }

  void _selectContact(Contact contact) {
    _isApplyingContactSelection = true;
    _contactSearchController.text = contact.displayName;
    _isApplyingContactSelection = false;
    setState(() {
      _selectedContactId = contact.id;
      _suggestions = const [];
    });
    FocusScope.of(context).unfocus();
  }

  void _clearContact() {
    _isApplyingContactSelection = true;
    _contactSearchController.clear();
    _isApplyingContactSelection = false;
    setState(() {
      _selectedContactId = null;
      _suggestions = const [];
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final timeError = Validators.appointmentEndTime(
      _minutesOf(_startTime),
      _minutesOf(_endTime),
    );
    if (timeError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(timeError)));
      return;
    }
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );
    Navigator.of(context).pop(
      Appointment(
        id: widget.existing?.id,
        title: _titleController.text.trim(),
        start: start,
        end: end,
        note: _noteController.text.trim(),
        category: _category,
        contactId: _selectedContactId,
      ),
    );
  }

  Widget _buildContactSearch() {
    if (widget.contacts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('appointment_contact_search'),
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Kontakt suchen (optional)',
              suffixIcon: Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Noch keine Kontakte gespeichert. Der Termin kann trotzdem '
            'erstellt werden.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('appointment_contact_search'),
          controller: _contactSearchController,
          decoration: InputDecoration(
            labelText: 'Kontakt suchen (optional)',
            suffixIcon: _selectedContactId != null
                ? IconButton(
                    tooltip: 'Verknüpfung entfernen',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearContact,
                  )
                : const Icon(Icons.search, size: 18),
          ),
          onChanged: _handleContactSearchChanged,
        ),
        if (_selectedContactId != null) ...[
          const SizedBox(height: 6),
          Text(
            'Mit „${_contactSearchController.text}“ verknüpft.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.sky600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_suggestions.isNotEmpty)
          Container(
            key: const Key('appointment_contact_suggestions'),
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            // Bewusst eine einfache Column statt eines ListView: die Liste
            // steckt bereits in der äusseren scrollbaren Dialog-Column, ein
            // zusätzlicher (auch shrinkWrap) Viewport an dieser Stelle
            // verträgt sich nicht mit deren Intrinsic-Height-Messung.
            // Kontaktlisten sind hier ausserdem klein genug, dass kein
            // eigenes Scrollen nötig ist.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.fieldBorder),
                  Builder(
                    builder: (context) {
                      final contact = _suggestions[i];
                      final details = [
                        if (contact.phone.isNotEmpty) contact.phone,
                        if (contact.email.isNotEmpty) contact.email,
                        if (contact.address.isNotEmpty) contact.address,
                      ].join(' · ');
                      return InkWell(
                        key: Key(
                          'appointment_contact_suggestion_${contact.id}',
                        ),
                        onTap: () => _selectContact(contact),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  details,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final timeError = Validators.appointmentEndTime(
      _minutesOf(_startTime),
      _minutesOf(_endTime),
    );
    return AlertDialog(
      title: Text(isEditing ? 'Termin bearbeiten' : 'Termin hinzufügen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('appointment_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  hintText: 'z. B. Besprechung mit Müller AG',
                ),
                validator: (v) => Validators.required(
                  v,
                  message: 'Bitte einen Titel eingeben',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('appointment_date_picker'),
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(_dateFormat.format(_date)),
                ),
              ),
              if (!isEditing && _isPastDate) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.privateOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dieses Datum liegt in der Vergangenheit.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.privateOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('appointment_start_time_picker'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickStartTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Startzeit',
                          suffixIcon: Icon(Icons.access_time, size: 18),
                        ),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      key: const Key('appointment_end_time_picker'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickEndTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Endzeit',
                          suffixIcon: const Icon(Icons.access_time, size: 18),
                          errorText: timeError,
                        ),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<AppointmentCategory>(
                key: const Key('appointment_category_selector'),
                segments: const [
                  ButtonSegment(
                    value: AppointmentCategory.business,
                    label: Text('Geschäftlich'),
                    icon: Icon(Icons.work_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: AppointmentCategory.private,
                    label: Text('Privat'),
                    icon: Icon(Icons.home_outlined, size: 16),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (selection) =>
                    setState(() => _category = selection.first),
              ),
              const SizedBox(height: 16),
              _buildContactSearch(),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('appointment_note_field'),
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notiz (optional)',
                ),
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
          key: const Key('appointment_save_button'),
          onPressed: _submit,
          child: Text(isEditing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }
}
