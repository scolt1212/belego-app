import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Zeigt das Firmenlogo proportional (nie verzerrt, `BoxFit.contain`) und
/// grössenbegrenzt an. Ist kein Logo vorhanden oder lassen sich die Daten
/// ausnahmsweise nicht darstellen, erscheint stattdessen ein ruhiger
/// Platzhalter mit den Firmen-Initialen bzw. einem neutralen Symbol –
/// niemals ein defektes Bild oder eine Fehlermeldung.
class CompanyLogoAvatar extends StatelessWidget {
  const CompanyLogoAvatar({
    super.key,
    required this.logoBytes,
    required this.companyName,
    this.size = 56,
  });

  final Uint8List? logoBytes;
  final String companyName;
  final double size;

  String get _initials {
    final words = companyName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    final hasLogo = logoBytes != null;
    return Semantics(
      label: hasLogo
          ? 'Firmenlogo'
          : 'Firmenkürzel${initials.isNotEmpty ? ' $initials' : ''}',
      image: hasLogo,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.sky50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: hasLogo
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: Image.memory(
                  logoBytes!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(initials),
                ),
              )
            : _placeholder(initials),
      ),
    );
  }

  Widget _placeholder(String initials) {
    return Center(
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.sky600,
                fontSize: size * 0.34,
              ),
            )
          : Icon(
              Icons.apartment_outlined,
              color: AppColors.sky600,
              size: size * 0.5,
            ),
    );
  }
}
