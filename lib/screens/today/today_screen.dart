import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../models/company_profile.dart';
import '../../models/contact.dart';
import '../../models/invoice_customer.dart';
import '../../models/invoice_draft.dart';
import '../../models/invoice_line_item.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/max_width_box.dart';
import '../documents/documents_screen.dart' show DocumentsFilter;
import 'widgets/belego_top_bar.dart';
import 'widgets/demo_mode_banner.dart';
import 'widgets/finance_overview_section.dart';
import 'widgets/hero_background.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/tasks_section.dart';
import 'widgets/today_header.dart';
import 'widgets/week_calendar_card.dart';

/// Zeitraum für die Umsatzkennzahl der Finanzübersicht. Beeinflusst
/// ausschliesslich die Umsatzberechnung – offene/überfällige Rechnungen sind
/// stets der aktuelle Stand, unabhängig vom gewählten Zeitraum.
enum FinancePeriod { thisMonth, thisYear, allTime }

/// Aggregierte Finanzkennzahlen, aus den tatsächlich gespeicherten
/// Rechnungen berechnet (siehe [TodayScreenState._computeFinance]).
class FinanceSummary {
  const FinanceSummary({
    required this.revenueRappen,
    required this.openCount,
    required this.openTotalRappen,
    required this.overdueCount,
    required this.overdueTotalRappen,
  });

  final int revenueRappen;
  final int openCount;
  final int openTotalRappen;
  final int overdueCount;
  final int overdueTotalRappen;
}

/// Startseite „Heute“: Kopfbereich, Finanzübersicht, Schnellaktionen,
/// Kalender/Termine und Aufgaben. Im Demo-Modus werden ausschliesslich
/// lokale, klar getrennte Beispieldaten angezeigt – diese werden nie in den
/// echten App-Zustand (z.B. den Dokumente-Tab) übernommen.
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.isDemoMode,
    required this.companyProfile,
    required this.invoices,
    required this.companyIsVatLiable,
    required this.appointments,
    required this.tasks,
    required this.contacts,
    required this.onCreateInvoice,
    required this.onOpenDocuments,
    required this.onLeaveDemo,
    required this.onAddAppointment,
    required this.onUpdateAppointment,
    required this.onDeleteAppointment,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  final bool isDemoMode;
  final CompanyProfile companyProfile;
  final List<InvoiceDraft> invoices;
  final bool companyIsVatLiable;
  final List<Appointment> appointments;
  final List<TaskItem> tasks;
  final List<Contact> contacts;

  final VoidCallback onCreateInvoice;
  final ValueChanged<DocumentsFilter> onOpenDocuments;
  final VoidCallback onLeaveDemo;

  final ValueChanged<Appointment> onAddAppointment;
  final ValueChanged<Appointment> onUpdateAppointment;
  final ValueChanged<String> onDeleteAppointment;

  final ValueChanged<TaskItem> onAddTask;
  final ValueChanged<String> onToggleTask;
  final ValueChanged<String> onDeleteTask;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _entranceStarted = false;

  FinancePeriod _financePeriod = FinancePeriod.thisMonth;

  // Demo-Daten: ausschliesslich für den Demo-Modus, komplett getrennt vom
  // echten App-Zustand. Werden nie in eine echte Rechnungsliste, den
  // Kalender oder die Aufgabenliste eines echten Kontos übernommen.
  late final List<InvoiceDraft> _demoInvoices = _buildDemoInvoices();
  late List<Appointment> _demoAppointments = _buildDemoAppointments();
  late List<TaskItem> _demoTasks = _buildDemoTasks();
  late final List<Contact> _demoContacts = _buildDemoContacts();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Einmaliges Einblenden beim ersten Öffnen; Lesen von MediaQuery ist in
    // initState() nicht sicher möglich, daher hier statt dort.
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  // --- Demo-Beispieldaten -------------------------------------------------

  List<InvoiceDraft> _buildDemoInvoices() {
    final now = DateTime.now();
    InvoiceDraft build({
      required String number,
      required DateTime date,
      required int termDays,
      required String customer,
      required int priceRappen,
      bool paid = false,
    }) {
      final draft = InvoiceDraft(
        invoiceNumber: number,
        invoiceDate: date,
        paymentTermDays: termDays,
      );
      if (paid) {
        draft.status = InvoiceStatus.paid;
        draft.paidAt = date;
      } else {
        draft.status = InvoiceStatus.open;
      }
      draft.customer = InvoiceCustomer()..companyOrName = customer;
      draft.items = [
        InvoiceLineItem(description: 'Leistung', unitPriceRappen: priceRappen),
      ];
      return draft;
    }

    return [
      build(
        number: 'RE-2026-DEMO1',
        date: DateTime(now.year, now.month, 3),
        termDays: 30,
        customer: 'Café Sonnenblick',
        priceRappen: 124000,
        paid: true,
      ),
      build(
        number: 'RE-2026-DEMO2',
        date: now.subtract(const Duration(days: 20)),
        termDays: 10,
        customer: 'Müller Bau GmbH',
        priceRappen: 95000,
      ),
      build(
        number: 'RE-2026-DEMO3',
        date: now.subtract(const Duration(days: 2)),
        termDays: 30,
        customer: 'Anna Schneider',
        priceRappen: 38050,
      ),
      build(
        number: 'RE-2026-DEMO4',
        date: DateTime(now.year, now.month - 1, 12),
        termDays: 30,
        customer: 'Gärtnerei Blumenfeld',
        priceRappen: 87000,
        paid: true,
      ),
    ];
  }

  List<Appointment> _buildDemoAppointments() {
    final now = DateTime.now();
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return [
      Appointment(
        title: 'Besprechung – Müller Bau GmbH',
        start: at(10),
        end: at(11),
        category: AppointmentCategory.business,
      ),
      Appointment(
        title: 'Materiallieferung prüfen',
        start: at(14),
        end: at(14, 30),
        category: AppointmentCategory.business,
      ),
      Appointment(
        title: 'Zahnarzttermin',
        start: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
        end: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10),
        category: AppointmentCategory.private,
      ),
    ];
  }

  List<Contact> _buildDemoContacts() {
    return [
      Contact(
        displayName: 'Müller Bau GmbH',
        phone: '+41 44 555 12 12',
        email: 'info@mueller-bau.example',
        address: 'Baustrasse 4, 8005 Zürich',
      ),
      Contact(displayName: 'Anna Schneider', phone: '+41 79 555 34 56'),
      Contact(
        displayName: 'Café Sonnenblick',
        email: 'kontakt@sonnenblick.example',
      ),
    ];
  }

  List<TaskItem> _buildDemoTasks() {
    final now = DateTime.now();
    return [
      TaskItem(
        title: 'Angebot an Müller Bau GmbH nachfassen',
        category: TaskCategory.business,
      ),
      TaskItem(
        title: 'Materialliste bestellen',
        dueDate: now.add(const Duration(days: 2)),
        category: TaskCategory.business,
      ),
      TaskItem(
        title: 'Zahnarzttermin bestätigen',
        isDone: true,
        category: TaskCategory.private,
      ),
    ];
  }

  // --- Berechnung der Finanzübersicht --------------------------------------

  static bool _paidAtIsInPeriod(
    DateTime paidAt,
    FinancePeriod period,
    DateTime now,
  ) {
    switch (period) {
      case FinancePeriod.thisMonth:
        return paidAt.year == now.year && paidAt.month == now.month;
      case FinancePeriod.thisYear:
        return paidAt.year == now.year;
      case FinancePeriod.allTime:
        return true;
    }
  }

  static String _revenueTitle(FinancePeriod period) {
    switch (period) {
      case FinancePeriod.thisMonth:
        return 'Umsatz diesen Monat';
      case FinancePeriod.thisYear:
        return 'Umsatz dieses Jahr';
      case FinancePeriod.allTime:
        return 'Gesamtumsatz';
    }
  }

  static String _revenueEmptyText(FinancePeriod period) {
    switch (period) {
      case FinancePeriod.thisMonth:
        return 'Noch keine bezahlten Rechnungen diesen Monat.';
      case FinancePeriod.thisYear:
        return 'Noch keine bezahlten Rechnungen dieses Jahr.';
      case FinancePeriod.allTime:
        return 'Noch keine bezahlten Rechnungen.';
    }
  }

  static String _periodLabel(FinancePeriod period) {
    switch (period) {
      case FinancePeriod.thisMonth:
        return 'Diesen Monat';
      case FinancePeriod.thisYear:
        return 'Dieses Jahr';
      case FinancePeriod.allTime:
        return 'Gesamt';
    }
  }

  /// Berechnungsregel: Umsatz = Summe der als bezahlt markierten Rechnungen,
  /// deren Zahlungsdatum (`paidAt`, gesetzt beim manuellen Markieren als
  /// bezahlt) im gewählten Zeitraum [period] liegt. „Offene Rechnungen“ =
  /// Anzahl/Summe aller gestellten (`status == open`), noch nicht bezahlten
  /// Rechnungen – unabhängig vom Zeitraum, da es sich um den aktuellen Stand
  /// handelt. „Überfällige Rechnungen“ = die Teilmenge davon, deren
  /// Fälligkeitsdatum bereits verstrichen ist. Entwürfe (`status == draft`)
  /// zählen in keiner dieser Summen – sie sind noch keine verbindliche
  /// Forderung. Es gibt keine automatische Banküberprüfung: eine Zahlung
  /// wird ausschliesslich durch die bewusste Aktion „Als bezahlt markieren“
  /// erfasst (siehe ROADMAP.md).
  FinanceSummary _computeFinance(
    List<InvoiceDraft> invoices,
    FinancePeriod period,
  ) {
    final now = DateTime.now();
    var revenue = 0;
    var openCount = 0;
    var openTotal = 0;
    var overdueCount = 0;
    var overdueTotal = 0;
    for (final invoice in invoices) {
      final total = invoice.totalRappen(
        companyIsVatLiable: widget.companyIsVatLiable,
      );
      switch (invoice.status) {
        case InvoiceStatus.draft:
          break;
        case InvoiceStatus.paid:
          final paidAt = invoice.paidAt;
          if (paidAt != null && _paidAtIsInPeriod(paidAt, period, now)) {
            revenue += total;
          }
        case InvoiceStatus.open:
          openCount += 1;
          openTotal += total;
          if (invoice.isOverdue) {
            overdueCount += 1;
            overdueTotal += total;
          }
      }
    }
    return FinanceSummary(
      revenueRappen: revenue,
      openCount: openCount,
      openTotalRappen: openTotal,
      overdueCount: overdueCount,
      overdueTotalRappen: overdueTotal,
    );
  }

  /// Echte Veränderung des Umsatzes zum Vormonat in Prozent, ausschliesslich
  /// aus den tatsächlich bezahlten Rechnungen berechnet. Liefert `null`,
  /// wenn der Vormonat keinen Umsatz hatte – eine Prozentangabe wäre dann
  /// nicht sinnvoll interpretierbar (z.B. „unendlich % mehr“), daher wird in
  /// diesem Fall bewusst keine erfundene Zahl gezeigt.
  double? _computeRevenueChangePercent(List<InvoiceDraft> invoices) {
    final series = _computeRevenueSeries(invoices, monthCount: 2);
    final previous = series.first.rappen;
    final current = series.last.rappen;
    if (previous <= 0) return null;
    return (current - previous) / previous * 100;
  }

  /// Umsatz je Monat aus ausschliesslich bezahlten Rechnungen (`paidAt`),
  /// für die letzten [monthCount] Monate inklusive des aktuellen Monats. Für
  /// das kleine Umsatzdiagramm auf „Heute“ – keine erfundenen Werte, ein
  /// Monat ohne bezahlte Rechnung ergibt schlicht `0`.
  List<MonthlyRevenue> _computeRevenueSeries(
    List<InvoiceDraft> invoices, {
    int monthCount = 6,
  }) {
    final now = DateTime.now();
    final months = List.generate(
      monthCount,
      (i) => DateTime(now.year, now.month - (monthCount - 1 - i)),
    );
    const monthLabels = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    return [
      for (final month in months)
        MonthlyRevenue(
          label: monthLabels[month.month - 1],
          rappen: invoices
              .where(
                (d) =>
                    d.status == InvoiceStatus.paid &&
                    d.paidAt != null &&
                    d.paidAt!.year == month.year &&
                    d.paidAt!.month == month.month,
              )
              .fold<int>(
                0,
                (sum, d) =>
                    sum +
                    d.totalRappen(
                      companyIsVatLiable: widget.companyIsVatLiable,
                    ),
              ),
        ),
    ];
  }

  // --- Termine --------------------------------------------------------------

  void _handleSaveAppointment(Appointment appointment) {
    final list = widget.isDemoMode ? _demoAppointments : widget.appointments;
    final exists = list.any((a) => a.id == appointment.id);
    if (widget.isDemoMode) {
      setState(() {
        _demoAppointments = exists
            ? [
                for (final a in _demoAppointments)
                  if (a.id == appointment.id) appointment else a,
              ]
            : [..._demoAppointments, appointment];
      });
    } else if (exists) {
      widget.onUpdateAppointment(appointment);
    } else {
      widget.onAddAppointment(appointment);
    }
  }

  void _handleDeleteAppointment(String id) {
    if (widget.isDemoMode) {
      setState(
        () => _demoAppointments = _demoAppointments
            .where((a) => a.id != id)
            .toList(),
      );
    } else {
      widget.onDeleteAppointment(id);
    }
  }

  // --- Aufgaben ---------------------------------------------------------

  void _handleAddTask(TaskItem task) {
    if (widget.isDemoMode) {
      setState(() => _demoTasks = [..._demoTasks, task]);
    } else {
      widget.onAddTask(task);
    }
  }

  void _handleToggleTask(String id) {
    if (widget.isDemoMode) {
      setState(() {
        for (final t in _demoTasks) {
          if (t.id == id) t.isDone = !t.isDone;
        }
      });
    } else {
      widget.onToggleTask(id);
    }
  }

  void _handleDeleteTask(String id) {
    if (widget.isDemoMode) {
      setState(() => _demoTasks = _demoTasks.where((t) => t.id != id).toList());
    } else {
      widget.onDeleteTask(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = widget.isDemoMode ? _demoInvoices : widget.invoices;
    final appointments = widget.isDemoMode
        ? _demoAppointments
        : widget.appointments;
    final tasks = widget.isDemoMode ? _demoTasks : widget.tasks;
    final contacts = widget.isDemoMode ? _demoContacts : widget.contacts;
    final companyName = widget.isDemoMode
        ? 'Gartenbau Meier GmbH'
        : widget.companyProfile.companyName;
    final firstName = widget.isDemoMode
        ? 'Nina'
        : widget.companyProfile.firstName;
    final logoBytes = widget.isDemoMode
        ? null
        : widget.companyProfile.logoBytes;
    final finance = _computeFinance(invoices, _financePeriod);
    final revenueChangePercent = _financePeriod == FinancePeriod.thisMonth
        ? _computeRevenueChangePercent(invoices)
        : null;

    final quickActions = [
      QuickAction(
        actionKey: const Key('quick_action_create_invoice'),
        icon: Icons.receipt_long_outlined,
        label: 'Rechnung erstellen',
        enabled: true,
        onTap: widget.onCreateInvoice,
      ),
      const QuickAction(
        actionKey: Key('quick_action_create_offer'),
        icon: Icons.description_outlined,
        label: 'Offerte erstellen',
        enabled: false,
        accentColor: AppColors.privateOrange,
      ),
      const QuickAction(
        actionKey: Key('quick_action_create_contract'),
        icon: Icons.article_outlined,
        label: 'Vertrag erstellen',
        enabled: false,
      ),
      const QuickAction(
        actionKey: Key('quick_action_add_contact'),
        icon: Icons.person_add_alt_outlined,
        label: 'Kontakt hinzufügen',
        enabled: false,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: HeroBackground()),
          SafeArea(
            child: MaxWidthBox(
              maxWidth: 960,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      const BelegoTopBar(),
                      const SizedBox(height: AppSpacing.md),
                      if (widget.isDemoMode) ...[
                        DemoModeBanner(onLeaveDemo: widget.onLeaveDemo),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const Text(
                        'Heute',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TodayHeader(
                        firstName: firstName,
                        companyName: companyName,
                        logoBytes: logoBytes,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Finanzübersicht',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _FinancePeriodDropdown(
                            value: _financePeriod,
                            onChanged: (period) =>
                                setState(() => _financePeriod = period),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FinanceOverviewSection(
                        revenueTitle: _revenueTitle(_financePeriod),
                        revenueRappen: finance.revenueRappen,
                        revenueChangePercent: revenueChangePercent,
                        revenueEmptyText: _revenueEmptyText(_financePeriod),
                        openCount: finance.openCount,
                        openTotalRappen: finance.openTotalRappen,
                        overdueCount: finance.overdueCount,
                        overdueTotalRappen: finance.overdueTotalRappen,
                        onTapOpen: widget.isDemoMode
                            ? null
                            : () =>
                                  widget.onOpenDocuments(DocumentsFilter.open),
                        onTapOverdue: widget.isDemoMode
                            ? null
                            : () => widget.onOpenDocuments(
                                DocumentsFilter.overdue,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RevenueChart(series: _computeRevenueSeries(invoices)),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Schnellaktionen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      QuickActionsSection(actions: quickActions),
                      const SizedBox(height: AppSpacing.lg),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final calendarCard = WeekCalendarCard(
                            key: const Key('week_calendar_card'),
                            appointments: appointments,
                            contacts: contacts,
                            onSaveAppointment: _handleSaveAppointment,
                            onDeleteAppointment: _handleDeleteAppointment,
                          );
                          final tasksCard = TasksSection(
                            key: const Key('tasks_section'),
                            tasks: tasks,
                            onAdd: _handleAddTask,
                            onToggle: _handleToggleTask,
                            onDelete: _handleDeleteTask,
                          );
                          if (constraints.maxWidth >= 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: calendarCard),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: tasksCard),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              calendarCard,
                              const SizedBox(height: AppSpacing.lg),
                              tasksCard,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancePeriodDropdown extends StatelessWidget {
  const _FinancePeriodDropdown({required this.value, required this.onChanged});

  final FinancePeriod value;
  final ValueChanged<FinancePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('finance_period_dropdown'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FinancePeriod>(
          value: value,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.sky600,
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.sky600,
          ),
          items: FinancePeriod.values
              .map(
                (period) => DropdownMenuItem(
                  value: period,
                  child: Text(_TodayScreenState._periodLabel(period)),
                ),
              )
              .toList(),
          onChanged: (period) {
            if (period != null) onChanged(period);
          },
        ),
      ),
    );
  }
}
