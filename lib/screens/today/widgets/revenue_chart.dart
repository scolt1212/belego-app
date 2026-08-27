import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/money.dart';

/// Umsatz eines einzelnen Monats (nur aus bezahlten Rechnungen), für das
/// Umsatzdiagramm auf „Heute“.
class MonthlyRevenue {
  const MonthlyRevenue({required this.label, required this.rappen});

  final String label;
  final int rappen;
}

/// Zurückhaltendes Linien-/Flächendiagramm des Umsatzes je Monat.
/// Datenquelle sind ausschliesslich bezahlte Rechnungen (siehe
/// `TodayScreen._computeRevenueSeries`) – keine erfundenen Werte. Die Linie
/// baut sich beim ersten Anzeigen sichtbar von links nach rechts auf, die
/// Fläche blendet sanft ein und die Punkte erscheinen leicht nacheinander.
/// Respektiert `MediaQuery.disableAnimations`.
class RevenueChart extends StatefulWidget {
  const RevenueChart({super.key, required this.series});

  final List<MonthlyRevenue> series;

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _growth;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _growth = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final hasRevenue = widget.series.any((m) => m.rappen > 0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppColors.sky600,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Umsatz je Monat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(left: 26),
                child: Text(
                  'Nur bezahlte Rechnungen',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!hasRevenue)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.query_stats,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Noch kein bezahlter Umsatz vorhanden.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _growth,
                  builder: (context, _) => SizedBox(
                    key: const Key('revenue_chart_canvas'),
                    height: 200,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _RevenueChartPainter(
                        series: widget.series,
                        progress: _growth.value,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({required this.series, required this.progress});

  final List<MonthlyRevenue> series;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final maxValue = series
        .map((m) => m.rappen)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final axisMax = maxValue <= 0 ? 1 : _niceAxisMax(maxValue);

    const leftAxisWidth = 34.0;
    const labelHeight = 20.0;
    final chartWidth = size.width - leftAxisWidth;
    final chartHeight = size.height - labelHeight;

    _drawAxisAndGrid(
      canvas,
      size,
      leftAxisWidth,
      chartWidth,
      chartHeight,
      axisMax,
    );

    final stepX = series.length > 1 ? chartWidth / (series.length - 1) : 0.0;
    Offset pointFor(int i) {
      final x = leftAxisWidth + stepX * i;
      final y = chartHeight - (series[i].rappen / axisMax) * chartHeight;
      return Offset(x, y);
    }

    // Linien-Fortschritt: wie viele volle Segmente plus Teilstück gezeichnet
    // werden, damit die Linie sichtbar von links nach rechts aufgebaut wird.
    final totalSegments = (series.length - 1).clamp(1, 1 << 30);
    final drawnSegments = progress * totalSegments;

    final visiblePoints = <Offset>[pointFor(0)];
    for (var i = 1; i < series.length; i++) {
      final segmentProgress = (drawnSegments - (i - 1)).clamp(0.0, 1.0);
      if (segmentProgress <= 0) break;
      final prev = pointFor(i - 1);
      final curr = pointFor(i);
      if (segmentProgress >= 1) {
        visiblePoints.add(curr);
      } else {
        visiblePoints.add(Offset.lerp(prev, curr, segmentProgress)!);
        break;
      }
    }

    if (visiblePoints.length >= 2) {
      final areaPath = Path()..moveTo(visiblePoints.first.dx, chartHeight);
      for (final p in visiblePoints) {
        areaPath.lineTo(p.dx, p.dy);
      }
      areaPath
        ..lineTo(visiblePoints.last.dx, chartHeight)
        ..close();
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sky500.withValues(alpha: 0.28),
            AppColors.sky500.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
      canvas.drawPath(areaPath, areaPaint);
    }

    final linePath = Path()
      ..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (final p in visiblePoints.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = AppColors.sky600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Punkte erscheinen leicht nacheinander (versetzt zur Linie).
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < series.length; i++) {
      final pointProgress = (progress * series.length - i * 0.6).clamp(
        0.0,
        1.0,
      );
      if (pointProgress <= 0) continue;
      final point = pointFor(i);
      final isLast = i == series.length - 1;
      final radius = (isLast ? 5.0 : 3.2) * pointProgress;
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = isLast ? AppColors.sky600 : AppColors.sky500,
      );
      if (isLast && pointProgress >= 1) {
        canvas.drawCircle(
          point,
          radius + 3,
          Paint()
            ..color = AppColors.sky500.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      textPainter
        ..text = TextSpan(
          text: series[i].label,
          style: TextStyle(
            fontSize: 11,
            color: isLast ? AppColors.sky600 : AppColors.textSecondary,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
          ),
        )
        ..layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, chartHeight + 4),
      );
    }

    // Wertblase über dem letzten (aktiven) Datenpunkt, mit gestrichelter
    // Hilfslinie zur Monatsachse (analog zur Referenzgestaltung).
    if (progress > 0.85) {
      final lastPoint = pointFor(series.length - 1);
      _drawDashedLine(
        canvas,
        Offset(lastPoint.dx, lastPoint.dy),
        Offset(lastPoint.dx, chartHeight),
        Paint()
          ..color = AppColors.sky500.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      final bubbleText = Money.formatRappen(series.last.rappen);
      textPainter
        ..text = TextSpan(
          text: bubbleText,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        )
        ..layout();
      final bubbleWidth = textPainter.width + 16;
      const bubbleHeight = 22.0;
      var bubbleLeft = lastPoint.dx - bubbleWidth / 2;
      bubbleLeft = bubbleLeft.clamp(0.0, size.width - bubbleWidth);
      final bubbleTop = (lastPoint.dy - bubbleHeight - 12).clamp(
        0.0,
        chartHeight,
      );
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(bubbleRect, Paint()..color = AppColors.sky600);
      textPainter.paint(
        canvas,
        Offset(
          bubbleLeft + 8,
          bubbleTop + (bubbleHeight - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawAxisAndGrid(
    Canvas canvas,
    Size size,
    double leftAxisWidth,
    double chartWidth,
    double chartHeight,
    int axisMax,
  ) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = chartHeight - (chartHeight / steps) * i;
      _drawDashedLine(
        canvas,
        Offset(leftAxisWidth, y),
        Offset(leftAxisWidth + chartWidth, y),
        gridPaint,
      );
      final value = (axisMax / 100 / steps * i).round();
      textPainter
        ..text = TextSpan(
          text: '$value',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        )
        ..layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const gapWidth = 4.0;
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    var drawn = 0.0;
    while (drawn < totalLength) {
      final segmentEnd = (drawn + dashWidth).clamp(0.0, totalLength);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * segmentEnd,
        paint,
      );
      drawn += dashWidth + gapWidth;
    }
  }

  /// Rundet auf eine „schöne“ Achsen-Obergrenze mit ca. 4 Rasterschritten
  /// auf (z.B. CHF 800 statt CHF 648.60), analog zur Referenzgestaltung.
  static int _niceAxisMax(int maxValueRappen) {
    final maxChf = maxValueRappen / 100;
    if (maxChf <= 0) return 40000;
    const divisions = 4;
    final rawStep = maxChf / divisions;
    final magnitude = _magnitudeOf(rawStep);
    final normalized = rawStep / magnitude;
    final niceNormalized = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    final niceStep = niceNormalized * magnitude;
    return ((niceStep * divisions) * 100).round();
  }

  static double _magnitudeOf(double value) {
    if (value <= 0) return 1;
    var magnitude = 1.0;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    while (magnitude > value) {
      magnitude /= 10;
    }
    return magnitude;
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.series != series;
}
