import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Grosse, weiche, organische hellblaue Wellenformen im oberen und unteren
/// Hintergrund der „Heute“-Seite. Rein dekorativ (`IgnorePointer`), bleibt
/// beim Scrollen des Inhalts an der Bildschirmposition fixiert (siehe
/// `TodayScreen`, das dies als unterste Ebene in einem `Stack` hinter dem
/// scrollbaren Inhalt platziert). Bewusst als `CustomPainter` statt
/// eingebetteter Bilddateien umgesetzt.
///
/// Baut sich beim ersten Öffnen innerhalb einer App-Sitzung einmalig sanft
/// auf (leichte Positionsbewegung + Einblenden, ~900ms) und steht danach
/// vollständig still – kein Loop, kein dauerhafter Ticker. Da `TodayScreen`
/// innerhalb eines `IndexedStack` lebt, bleibt dieser State beim Wechsel
/// zwischen den unteren Tabs erhalten, wodurch die Animation dort nicht neu
/// startet. Respektiert `MediaQuery.disableAnimations` (reduzierte
/// Bewegung): in diesem Fall erscheinen die Wellen sofort in ihrer
/// Endposition.
class HeroBackground extends StatefulWidget {
  const HeroBackground({super.key});

  @override
  State<HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<HeroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nur beim allerersten Aufbau dieses States starten (einmal pro
    // App-Sitzung, siehe Klassendokumentation) – MediaQuery ist in
    // initState() noch nicht sicher verfügbar, daher hier statt dort.
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) =>
                CustomPaint(painter: _WavePainter(progress: _progress.value)),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress});

  /// 0 = Startzustand (leicht verschoben, unsichtbar), 1 = Endzustand
  /// (fertige Position, volle Deckkraft). Bereits ge-eased.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Dezente Positionsbewegung: die Wellen gleiten aus einer leicht
    // abgesetzten Position sanft in ihre endgültige Lage.
    final settle = (1 - progress) * 18;
    canvas.save();
    canvas.translate(0, settle);
    _paintTopWaves(canvas, size, progress);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -settle);
    _paintBottomWaves(canvas, size, progress);
    canvas.restore();
  }

  void _paintTopWaves(Canvas canvas, Size size, double alpha) {
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
        ..color = AppColors.sky100.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
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
        ..color = AppColors.waveSecondary.withValues(alpha: 0.95 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Feiner, kräftiger Akzentschimmer ganz oben rechts (Belego-Blau, sehr
    // transparent) für den letzten Tiefeneindruck.
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.02),
      w * 0.28,
      Paint()
        ..color = AppColors.sky500.withValues(alpha: 0.14 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  void _paintBottomWaves(Canvas canvas, Size size, double alpha) {
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
        ..color = AppColors.sky100.withValues(alpha: 0.95 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
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
        ..color = AppColors.waveSecondary.withValues(alpha: 0.9 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
