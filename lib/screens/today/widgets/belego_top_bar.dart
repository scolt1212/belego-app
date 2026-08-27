import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Oberster Kopfbereich der „Heute“-Seite: Menü links, Belego-Markenlogo
/// mittig, Benachrichtigungssymbol rechts. Dies ist die Marke der App
/// selbst (nicht das Firmenlogo des Benutzers, das weiterhin bei der
/// Begrüssung erscheint).
class BelegoTopBar extends StatelessWidget {
  const BelegoTopBar({super.key, this.hasNotifications = false});

  final bool hasNotifications;

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Menü',
          child: IconButton(
            key: const Key('top_bar_menu_button'),
            tooltip: 'Menü (bald verfügbar)',
            onPressed: () => _showComingSoon(
              context,
              'Menü folgt in einem späteren Schritt.',
            ),
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.sky500, AppColors.sky600],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Belego',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: hasNotifications
              ? 'Benachrichtigungen, neue vorhanden'
              : 'Benachrichtigungen',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: const Key('top_bar_notifications_button'),
                tooltip: 'Benachrichtigungen (bald verfügbar)',
                onPressed: () =>
                    _showComingSoon(context, 'Noch keine Benachrichtigungen.'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                ),
              ),
              if (hasNotifications)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.sky600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
