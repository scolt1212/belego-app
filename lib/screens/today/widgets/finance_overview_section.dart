import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/money.dart';
import '../../../widgets/pressable.dart';

/// Drei Karten mit Umsatz, offenen und überfälligen Rechnungen – berechnet
/// aus den tatsächlich gespeicherten Rechnungen, siehe `TodayScreen` für die
/// genaue Berechnung.
class FinanceOverviewSection extends StatelessWidget {
  const FinanceOverviewSection({
    super.key,
    required this.revenueTitle,
    required this.revenueRappen,
    required this.revenueChangePercent,
    required this.revenueEmptyText,
    required this.openCount,
    required this.openTotalRappen,
    required this.overdueCount,
    required this.overdueTotalRappen,
    this.onTapOpen,
    this.onTapOverdue,
  });

  final String revenueTitle;
  final int revenueRappen;

  /// Echte, aus vorhandenen Daten berechnete Veränderung zum Vormonat in
  /// Prozent – `null`, wenn keine sinnvolle Vergleichsbasis existiert (dann
  /// wird eine neutrale Information statt einer erfundenen Zahl gezeigt).
  final double? revenueChangePercent;

  /// Text für den Fall, dass es noch keine bezahlten Rechnungen gibt –
  /// bewusst passend zum gewählten Zeitraum formuliert (z.B. „…diesen
  /// Monat.“), damit keine falsche Aussage entsteht.
  final String revenueEmptyText;

  final int openCount;
  final int openTotalRappen;
  final int overdueCount;
  final int overdueTotalRappen;
  final VoidCallback? onTapOpen;
  final VoidCallback? onTapOverdue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final revenueBadge = revenueRappen == 0
            ? _FinanceBadge(
                icon: Icons.info_outline,
                text: revenueEmptyText,
                color: AppColors.textSecondary,
                bg: AppColors.draftGreyBg,
              )
            : revenueChangePercent == null
            ? _FinanceBadge(
                icon: Icons.info_outline,
                text: 'Aus bezahlten Rechnungen',
                color: AppColors.textSecondary,
                bg: AppColors.draftGreyBg,
              )
            : _FinanceBadge(
                icon: revenueChangePercent! >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                text:
                    '${revenueChangePercent! >= 0 ? '+' : ''}${revenueChangePercent!.toStringAsFixed(1)}% vs. Vormonat',
                color: revenueChangePercent! >= 0
                    ? AppColors.paidGreen
                    : AppColors.textSecondary,
                bg: revenueChangePercent! >= 0
                    ? AppColors.paidGreenBg
                    : AppColors.draftGreyBg,
              );

        final cards = [
          _FinanceCard(
            key: const Key('finance_card_revenue'),
            icon: Icons.trending_up_rounded,
            accent: AppColors.sky600,
            tint: AppColors.sky100,
            title: revenueTitle,
            valueRappen: revenueRappen,
            badge: revenueBadge,
          ),
          _FinanceCard(
            key: const Key('finance_card_open'),
            icon: Icons.description_outlined,
            accent: AppColors.privateOrange,
            tint: AppColors.privateOrangeBg,
            title: 'Offene Rechnungen',
            valueRappen: openTotalRappen,
            badge: _FinanceBadge(
              icon: Icons.schedule,
              text: openCount == 0
                  ? 'Keine offenen Rechnungen.'
                  : (openCount == 1
                        ? '1 offene Rechnung'
                        : '$openCount offene Rechnungen'),
              color: AppColors.privateOrange,
              bg: AppColors.privateOrangeBg,
            ),
            onTap: onTapOpen,
          ),
          _FinanceCard(
            key: const Key('finance_card_overdue'),
            icon: overdueCount > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            accent: overdueCount > 0 ? AppColors.danger : AppColors.paidGreen,
            tint: overdueCount > 0 ? AppColors.dangerBg : AppColors.paidGreenBg,
            title: 'Überfällige Rechnungen',
            valueRappen: overdueTotalRappen,
            badge: _FinanceBadge(
              icon: overdueCount > 0 ? Icons.priority_high : Icons.check,
              text: overdueCount == 0
                  ? 'Alles im grünen Bereich'
                  : (overdueCount == 1
                        ? '1 überfällig'
                        : '$overdueCount überfällig'),
              color: overdueCount > 0 ? AppColors.danger : AppColors.paidGreen,
              bg: overdueCount > 0 ? AppColors.dangerBg : AppColors.paidGreenBg,
            ),
            onTap: onTapOverdue,
            emphasize: overdueCount > 0,
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _FinanceBadge {
  const _FinanceBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.title,
    required this.valueRappen,
    required this.badge,
    this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final Color accent;
  final Color tint;
  final String title;
  final int valueRappen;
  final _FinanceBadge badge;
  final VoidCallback? onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: onTap != null,
      label: '$title: ${Money.formatRappen(valueRappen)}. ${badge.text}',
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tint == AppColors.surface
                  ? AppColors.border
                  : accent.withValues(alpha: 0.25),
            ),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: valueRappen.toDouble()),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) => Text(
                    Money.formatRappen(animatedValue.round()),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: emphasize
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badge.icon, size: 12, color: badge.color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          badge.text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badge.color,
                          ),
                        ),
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
