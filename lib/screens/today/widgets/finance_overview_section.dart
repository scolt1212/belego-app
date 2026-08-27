import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/money.dart';
import '../../../widgets/pressable.dart';

/// Drei Karten mit Umsatz, offenen und überfälligen Rechnungen – berechnet
/// aus den tatsächlich gespeicherten Rechnungen, siehe `TodayScreen` für die
/// genaue Berechnung. Bleiben auf jeder Smartphonebreite nebeneinander (siehe
/// [_FinanceCard]); es gibt bewusst keine gestapelte Variante mehr, damit nie
/// eine Karte ausserhalb des Bildschirms liegt oder seitlich gescrollt
/// werden müsste.
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
        // Stetiger Skalierungsfaktor statt fester Haltepunkte (z.B. „nur bei
        // 375px“): 400 logische Pixel gelten als komfortable Breite für drei
        // Karten, darunter wird alles proportional kompakter, nach oben hin
        // wächst nichts mehr über die Komfort-Grösse hinaus.
        final scale = (constraints.maxWidth / 400).clamp(0.6, 1.0);
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
            scale: scale,
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
            scale: scale,
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
            scale: scale,
          ),
        ];

        final gap = (8 * scale).clamp(4.0, 8.0);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: cards[i]),
              ],
            ],
          ),
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
    required this.scale,
    this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final Color accent;
  final Color tint;
  final String title;
  final int valueRappen;
  final _FinanceBadge badge;
  final double scale;
  final VoidCallback? onTap;
  final bool emphasize;

  /// Skaliert [base] mit [scale], nie unter [min] – so bleibt jedes Element
  /// auch auf sehr schmalen Geräten noch klar erkennbar statt zu
  /// verschwinden.
  double _s(double base, double min) => (base * scale).clamp(min, base);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final iconBoxSize = _s(36, 24);
    final iconSize = _s(18, 13);
    final titleFontSize = _s(13, 10.5);
    final valueFontSize = _s(19, 14);
    final badgeFontSize = _s(11, 8.5);
    final badgeIconSize = _s(12, 9);
    return Semantics(
      button: onTap != null,
      label: '$title: ${Money.formatRappen(valueRappen)}. ${badge.text}',
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tint == AppColors.surface
                  ? AppColors.border
                  : accent.withValues(alpha: 0.25),
            ),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: EdgeInsets.all(_s(16, 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(_s(11, 7)),
                  ),
                  child: Icon(icon, size: iconSize, color: accent),
                ),
                SizedBox(height: _s(10, 5)),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: _s(6, 3)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: valueRappen.toDouble()),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Money.formatRappen(animatedValue.round()),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w800,
                        color: emphasize
                            ? AppColors.danger
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _s(8, 4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _s(8, 5),
                    vertical: _s(4, 2),
                  ),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badge.icon, size: badgeIconSize, color: badge.color),
                      SizedBox(width: _s(4, 2)),
                      Flexible(
                        child: Text(
                          badge.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: badgeFontSize,
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
