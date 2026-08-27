import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Grosse, weiche, organische hellblaue Wellenformen im oberen und unteren
/// Hintergrund der „Heute“-Seite. Rein dekorativ (`IgnorePointer`), bleibt
/// beim Scrollen des Inhalts an der Bildschirmposition fixiert (siehe
/// `TodayScreen`, das dies als unterste Ebene in einem `Stack` hinter dem
/// scrollbaren Inhalt platziert). Bewusst als `CustomPainter` statt
/// eingebetteter Bilddateien umgesetzt.
class HeroBackground extends StatelessWidget {
  const HeroBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(child: CustomPaint(painter: _WavePainter())),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintTopWaves(canvas, size);
    _paintBottomWaves(canvas, size);
  }

  void _paintTopWaves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grosse, helle Basiswelle – spannt fast die volle Breite, leicht nach
    // rechts geneigt, mit weichem Blur statt harter Vektorkante.
    final back = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.16)
      ..cubicTo(w * 0.78, h * 0.30, w * 0.55, h * 0.04, w * 0.32, h * 0.16)
      ..cubicTo(w * 0.16, h * 0.24, w * 0.06, h * 0.10, 0, h * 0.13)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..color = AppColors.sky100.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );

    // Zweite, etwas kräftigere Welle oben rechts – erzeugt die
    // charakteristische Tiefe/Schichtung aus der Referenz.
    final front = Path()
      ..moveTo(w * 0.35, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.09)
      ..cubicTo(w * 0.88, h * 0.20, w * 0.68, h * 0.02, w * 0.50, h * 0.10)
      ..cubicTo(w * 0.42, h * 0.13, w * 0.37, h * 0.06, w * 0.35, 0)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..color = AppColors.waveSecondary.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    // Feiner, kräftiger Akzentschimmer ganz oben rechts (Belego-Blau, sehr
    // transparent) für den letzten Tiefeneindruck.
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.02),
      w * 0.28,
      Paint()
        ..color = AppColors.sky500.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  void _paintBottomWaves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final back = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..cubicTo(w * 0.20, h * 0.72, w * 0.30, h * 0.92, w * 0.48, h * 0.86)
      ..cubicTo(w * 0.62, h * 0.82, w * 0.66, h * 0.94, w * 0.80, h)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..color = AppColors.sky100.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );

    final front = Path()
      ..moveTo(w * 0.55, h)
      ..lineTo(w, h)
      ..lineTo(w, h * 0.88)
      ..cubicTo(w * 0.9, h * 0.80, w * 0.78, h * 0.98, w * 0.65, h * 0.92)
      ..cubicTo(w * 0.60, h * 0.90, w * 0.57, h * 0.95, w * 0.55, h)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..color = AppColors.waveSecondary.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
