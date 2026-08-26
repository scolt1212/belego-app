import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Übersichtliche Fortschrittsanzeige für die Firmeneinrichtung.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.currentStep,
    required this.titles,
  });

  /// 0-basierter Index des aktuellen Schritts.
  final int currentStep;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < titles.length; i++) ...[
                _StepDot(
                  isDone: i < currentStep,
                  isActive: i == currentStep,
                  number: i + 1,
                ),
                if (i != titles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < currentStep
                          ? AppColors.sky600
                          : AppColors.border,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Schritt ${currentStep + 1} von ${titles.length} – ${titles[currentStep]}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.isDone,
    required this.isActive,
    required this.number,
  });

  final bool isDone;
  final bool isActive;
  final int number;

  @override
  Widget build(BuildContext context) {
    final highlighted = isDone || isActive;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.sky600 : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted ? AppColors.sky600 : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
    );
  }
}
