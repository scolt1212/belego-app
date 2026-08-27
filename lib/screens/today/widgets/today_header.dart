import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/company_logo_avatar.dart';

/// Begrüssung mit echtem Vornamen, Datum und Firmenlogo.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.firstName,
    required this.companyName,
    required this.logoBytes,
  });

  final String firstName;
  final String companyName;
  final Uint8List? logoBytes;

  static final DateFormat _swissLongDateFormat = DateFormat(
    'EEEE, d. MMMM yyyy',
    'de_CH',
  );

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen';
    if (hour < 18) return 'Guten Tag';
    return 'Guten Abend';
  }

  @override
  Widget build(BuildContext context) {
    final name = firstName.trim();
    final dateText = _swissLongDateFormat.format(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '${_greeting()}${name.isEmpty ? '' : ', '}'),
                    if (name.isNotEmpty)
                      TextSpan(
                        text: name,
                        style: const TextStyle(color: AppColors.sky600),
                      ),
                    if (name.isNotEmpty) const TextSpan(text: '  👋'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        CompanyLogoAvatar(
          logoBytes: logoBytes,
          companyName: companyName,
          size: 44,
        ),
      ],
    );
  }
}
