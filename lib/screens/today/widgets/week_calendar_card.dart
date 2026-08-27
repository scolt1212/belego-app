import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/appointment.dart';
import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pressable.dart';
import 'appointment_editor_dialog.dart';

enum _CalendarViewMode { week, month }

/// Kalenderkarte mit Wochen- und Monatsansicht. Der Nutzer ist nicht auf die
/// aktuelle Woche beschränkt: vorherige/nächste Woche, beliebige zukünftige
/// oder vergangene Wochen sowie eine vollständige Monatsansicht mit
/// Monat-/Jahresauswahl sind möglich. Beim Antippen eines Tages werden
/// dessen Termine darunter angezeigt.
class WeekCalendarCard extends StatefulWidget {
  const WeekCalendarCard({
    super.key,
    required this.appointments,
    required this.contacts,
    required this.onSaveAppointment,
    required this.onDeleteAppointment,
  });

  /// Alle Termine (nicht nur des ausgewählten Tages) – für die Punkte im
  /// Kalender.
  final List<Appointment> appointments;

  /// Für die optionale Kontaktsuche im Termin-Dialog.
  final List<Contact> contacts;
  final ValueChanged<Appointment> onSaveAppointment;
  final ValueChanged<String> onDeleteAppointment;

  @override
  State<WeekCalendarCard> createState() => _WeekCalendarCardState();
}

class _WeekCalendarCardState extends State<WeekCalendarCard> {
  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  late DateTime _selectedDay = _today();
  late DateTime _anchorDate = _today();
  _CalendarViewMode _viewMode = _CalendarViewMode.week;

  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'de_CH');
  static final DateFormat _dayMonthFormat = DateFormat('d. MMMM', 'de_CH');

  bool _hasCategory(DateTime day, AppointmentCategory category) =>
      widget.appointments.any((a) => a.isOnDay(day) && a.category == category);

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _anchorDate = day;
    });
  }

  void _shiftWeek(int deltaWeeks) {
    setState(
      () => _anchorDate = _anchorDate.add(Duration(days: 7 * deltaWeeks)),
    );
  }

  void _shiftMonth(int deltaMonths) {
    setState(() => _anchorDate = addMonths(_anchorDate, deltaMonths));
  }

  Future<void> _openMonthYearPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(_anchorDate.year - 10),
      lastDate: DateTime(_anchorDate.year + 10),
      helpText: 'Monat und Jahr wählen',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _anchorDate = DateTime(picked.year, picked.month, 1));
    }
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final result = await showAppointmentEditorDialog(
      context,
      initialDate: _selectedDay,
      contacts: widget.contacts,
    );
    if (result != null) widget.onSaveAppointment(result);
  }

  Future<void> _openEditDialog(
    BuildContext context,
    Appointment appointment,
  ) async {
    final result = await showAppointmentEditorDialog(
      context,
      initialDate: appointment.date,
      existing: appointment,
      contacts: widget.contacts,
    );
    if (result != null) widget.onSaveAppointment(result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('„${appointment.title}“ wird endgültig gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDeleteAppointment(appointment.id);
  }

  @override
  Widget build(BuildContext context) {
    final dayAppointments =
        widget.appointments.where((a) => a.isOnDay(_selectedDay)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

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
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.sky600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kalender',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SegmentedButton<_CalendarViewMode>(
                    key: const Key('calendar_view_mode_toggle'),
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: _CalendarViewMode.week,
                        label: Text('Woche'),
                      ),
                      ButtonSegment(
                        value: _CalendarViewMode.month,
                        label: Text('Monat'),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (selection) =>
                        setState(() => _viewMode = selection.first),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  _LegendDot(color: AppColors.businessBlue),
                  Text(
                    'Geschäftlich',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 10),
                  _LegendDot(color: AppColors.privateOrange),
                  Text(
                    'Privat',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CalendarNavRow(
                label: _viewMode == _CalendarViewMode.week
                    ? _weekRangeLabel(_anchorDate)
                    : _monthYearFormat.format(_anchorDate),
                onPrev: () => _viewMode == _CalendarViewMode.week
                    ? _shiftWeek(-1)
                    : _shiftMonth(-1),
                onNext: () => _viewMode == _CalendarViewMode.week
                    ? _shiftWeek(1)
                    : _shiftMonth(1),
                onLabelTap: () => _openMonthYearPicker(context),
              ),
              const SizedBox(height: 12),
              if (_viewMode == _CalendarViewMode.week)
                _WeekStrip(
                  anchorDate: _anchorDate,
                  selectedDay: _selectedDay,
                  today: _today(),
                  hasCategory: _hasCategory,
                  onDaySelected: _selectDay,
                )
              else
                _MonthGrid(
                  anchorDate: _anchorDate,
                  selectedDay: _selectedDay,
                  today: _today(),
                  hasCategory: _hasCategory,
                  onDaySelected: _selectDay,
                ),
              const SizedBox(height: 16),
              Text(
                _dayMonthFormat.format(_selectedDay),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (dayAppointments.isEmpty)
                const Text(
                  'Für diesen Tag sind keine Termine vorhanden.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final appointment in dayAppointments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AppointmentTile(
                          appointment: appointment,
                          onEdit: () => _openEditDialog(context, appointment),
                          onDelete: () => _confirmDelete(context, appointment),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              _PillButton(
                buttonKey: dayAppointments.isEmpty
                    ? const Key('add_appointment_empty_button')
                    : const Key('add_appointment_inline_button'),
                label: 'Termin hinzufügen',
                onTap: () => _openAddDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final DateFormat _dayFormat = DateFormat('d.');
  static final DateFormat _dayMonthShortFormat = DateFormat('d. MMM', 'de_CH');

  String _weekRangeLabel(DateTime anchor) {
    final start = startOfWeek(anchor);
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${_dayFormat.format(start)} – ${_dayMonthShortFormat.format(end)} ${end.year}';
    }
    return '${_dayMonthShortFormat.format(start)} – ${_dayMonthShortFormat.format(end)} ${end.year}';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CalendarNavRow extends StatelessWidget {
  const _CalendarNavRow({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onLabelTap,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onLabelTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('calendar_prev_button'),
          tooltip: 'Vorherige Periode',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        Expanded(
          child: InkWell(
            key: const Key('calendar_label_button'),
            borderRadius: BorderRadius.circular(10),
            onTap: onLabelTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('calendar_next_button'),
          tooltip: 'Nächste Periode',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.anchorDate,
    required this.selectedDay,
    required this.today,
    required this.hasCategory,
    required this.onDaySelected,
  });

  final DateTime anchorDate;
  final DateTime selectedDay;
  final DateTime today;
  final bool Function(DateTime day, AppointmentCategory category) hasCategory;
  final ValueChanged<DateTime> onDaySelected;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final weekStart = startOfWeek(anchorDate);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(
              day: day,
              isToday: _isSameDay(day, today),
              isSelected: _isSameDay(day, selectedDay),
              isDimmed: false,
              hasBusinessAppointment: hasCategory(
                day,
                AppointmentCategory.business,
              ),
              hasPrivateAppointment: hasCategory(
                day,
                AppointmentCategory.private,
              ),
              onTap: () => onDaySelected(day),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.anchorDate,
    required this.selectedDay,
    required this.today,
    required this.hasCategory,
    required this.onDaySelected,
  });

  final DateTime anchorDate;
  final DateTime selectedDay;
  final DateTime today;
  final bool Function(DateTime day, AppointmentCategory category) hasCategory;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(anchorDate.year, anchorDate.month, 1);
    final gridStart = startOfWeek(monthStart);
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    return Column(
      key: const Key('calendar_month_grid'),
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: _DayCell(
                    day: days[week * 7 + d],
                    isToday: _isSameDay(days[week * 7 + d], today),
                    isSelected: _isSameDay(days[week * 7 + d], selectedDay),
                    isDimmed: days[week * 7 + d].month != anchorDate.month,
                    hasBusinessAppointment: hasCategory(
                      days[week * 7 + d],
                      AppointmentCategory.business,
                    ),
                    hasPrivateAppointment: hasCategory(
                      days[week * 7 + d],
                      AppointmentCategory.private,
                    ),
                    onTap: () => onDaySelected(days[week * 7 + d]),
                    compact: true,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isDimmed,
    required this.hasBusinessAppointment,
    required this.hasPrivateAppointment,
    required this.onTap,
    this.compact = false,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isDimmed;
  final bool hasBusinessAppointment;
  final bool hasPrivateAppointment;
  final VoidCallback onTap;
  final bool compact;

  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    // Die ausgewählte Tagesfläche bleibt unabhängig von den Terminfarben
    // immer sky-blau markiert.
    final bgColor = isSelected
        ? AppColors.sky600
        : (isToday ? AppColors.sky100 : Colors.transparent);
    final textColor = isSelected
        ? Colors.white
        : (isDimmed
              ? AppColors.textSecondary.withValues(alpha: 0.5)
              : AppColors.textPrimary);
    final weekdayLabel = _weekdayLabels[day.weekday - 1];
    final markerLabel = switch ((
      hasBusinessAppointment,
      hasPrivateAppointment,
    )) {
      (true, true) => ' Geschäftliche und private Termine vorhanden',
      (true, false) => ' Geschäftlicher Termin vorhanden',
      (false, true) => ' Privater Termin vorhanden',
      (false, false) => '',
    };
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$weekdayLabel, ${day.day}.${day.month}.$markerLabel',
      child: Pressable(
        key: Key('calendar_day_${day.year}-${day.month}-${day.day}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(compact ? 8 : 12),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.sky600, width: 1.4)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact) ...[
                  Text(
                    weekdayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasBusinessAppointment)
                        _CategoryDot(
                          color: AppColors.businessBlue,
                          ringColor: isSelected ? Colors.white : null,
                        ),
                      if (hasBusinessAppointment && hasPrivateAppointment)
                        const SizedBox(width: 3),
                      if (hasPrivateAppointment)
                        _CategoryDot(
                          color: AppColors.privateOrange,
                          ringColor: isSelected ? Colors.white : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.color, this.ringColor});

  final Color color;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 0.6)
            : null,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
  });

  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final isBusiness = appointment.category == AppointmentCategory.business;
    final color = isBusiness ? AppColors.businessBlue : AppColors.privateOrange;
    final categoryLabel = isBusiness ? 'Geschäftlich' : 'Privat';
    return Semantics(
      label:
          'Termin ${appointment.title}, ${_timeFormat.format(appointment.start)} '
          'bis ${_timeFormat.format(appointment.end)}, $categoryLabel',
      child: Container(
        key: Key('appointment_${appointment.id}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sky50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_timeFormat.format(appointment.start)} – '
                    '${_timeFormat.format(appointment.end)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('appointment_edit_${appointment.id}'),
              tooltip: 'Termin bearbeiten',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              key: Key('appointment_delete_${appointment.id}'),
              tooltip: 'Termin löschen',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ),
      ),
    );
  }
}
