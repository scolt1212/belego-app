import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/pressable.dart';

/// Eine Schnellaktion. Ist [enabled] `false`, wird die Aktion sichtbar als
/// „Bald verfügbar“ dargestellt und ist nicht antippbar – sie darf niemals
/// wie eine funktionierende Aktion aussehen, die nur einen leeren
/// Platzhalter öffnet.
class QuickAction {
  const QuickAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.enabled,
    this.accentColor = AppColors.sky600,
    this.onTap,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final bool enabled;
  final Color accentColor;
  final VoidCallback? onTap;
}

/// Kompakter Bereich „Schnellaktionen“ – grosse Kacheln mit Icon, Titel
/// und einem kleinen Pfeil (bzw. „Bald verfügbar“ für noch nicht
/// umgesetzte Aktionen).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Bewusst kein GridView: ein scrollbarer Viewport innerhalb des
        // äusseren „Heute“-ListView (gleiche Achse) kann die Semantik-
        // Struktur durcheinanderbringen. Ein manuelles Zeilenraster
        // vermeidet das verschachtelte Viewport-Problem vollständig.
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < actions.length; i += columns) {
          final rowActions = actions.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: 12),
                    Expanded(
                      child: j < rowActions.length
                          ? _QuickActionTile(action: rowActions[j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.enabled ? action.accentColor : AppColors.draftGrey;
    return Semantics(
      button: true,
      enabled: action.enabled,
      label: action.enabled ? action.label : '${action.label}, bald verfügbar',
      child: Pressable(
        key: action.actionKey,
        onTap: action.enabled ? action.onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.enabled
                  ? AppColors.border
                  : AppColors.border.withValues(alpha: 0.6),
            ),
            boxShadow: action.enabled ? AppShadows.card : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: color, size: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: action.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (action.enabled)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: action.accentColor,
                      ),
                    ),
                  )
                else
                  const Text(
                    'Bald verfügbar',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
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
