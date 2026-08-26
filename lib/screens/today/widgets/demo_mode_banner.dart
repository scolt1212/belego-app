import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Dezenter, aber sichtbarer Hinweis, dass Beispieldaten angezeigt werden.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key, required this.onLeaveDemo});

  final VoidCallback onLeaveDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sky50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sky100),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: AppColors.sky600,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Demo-Modus – Beispieldaten',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.sky600,
              ),
            ),
          ),
          TextButton(
            key: const Key('leave_demo_button'),
            onPressed: onLeaveDemo,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Demo verlassen'),
          ),
        ],
      ),
    );
  }
}
