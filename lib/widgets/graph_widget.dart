import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive custom-painted chart widget for plotting BJT characteristic curves.
class BjtCurveChart extends StatelessWidget {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<CurveSeries> seriesList;
  final String xUnit;
  final String yUnit;

  const BjtCurveChart({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.seriesList,
    this.xUnit = 'V',
    this.yUnit = 'mA',
  });

  @override
  Widget build(BuildContext context) {
    final hasData = seriesList.any((s) => s.points.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Wrap(
                spacing: 12,
                children: seriesList.map((s) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.name,
                        style: TextStyle(color: s.color, fontSize: 11),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: hasData
                ? CustomPaint(
                    painter: _BjtChartPainter(
                      seriesList: seriesList,
                      xLabel: xLabel,
                      yLabel: yLabel,
                      xUnit: xUnit,
                      yUnit: yUnit,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_graph, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'No experimental points recorded yet.\nAdd readings in the table to plot the curve.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CurveSeries {
  final String name;
  final Color color;
  final List<PointData> points;

  const CurveSeries({
    required this.name,
    required this.color,
    required this.points,
  });
}

class PointData {
  final double x;
  final double y;

  const PointData(this.x, this.y);
}

class _BjtChartPainter extends CustomPainter {
  final List<CurveSeries> seriesList;
  final String xLabel;
  final String yLabel;
  final String xUnit;
  final String yUnit;

  _BjtChartPainter({
    required this.seriesList,
    required this.xLabel,
    required this.yLabel,
    required this.xUnit,
    required this.yUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 45;
    const double paddingBottom = 35;
    const double paddingTop = 15;
    const double paddingRight = 15;

    final double plotWidth = size.width - paddingLeft - paddingRight;
    final double plotHeight = size.height - paddingTop - paddingBottom;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    // Determine max X and max Y
    double maxX = 1.0;
    double maxY = 1.0;

    for (final s in seriesList) {
      for (final p in s.points) {
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    // Add 10% headroom
    maxX *= 1.15;
    maxY *= 1.15;

    final gridPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 9);

    // Draw 5 horizontal grid lines & Y labels
    for (int i = 0; i <= 5; i++) {
      final double yRatio = i / 5.0;
      final double yPos = paddingTop + plotHeight * (1.0 - yRatio);
      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(paddingLeft + plotWidth, yPos),
        gridPaint,
      );

      final yVal = (maxY * yRatio).toStringAsFixed(1);
      final textSpan = TextSpan(text: yVal, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, yPos - 5));
    }

    // Draw 5 vertical grid lines & X labels
    for (int i = 0; i <= 5; i++) {
      final double xRatio = i / 5.0;
      final double xPos = paddingLeft + plotWidth * xRatio;
      canvas.drawLine(
        Offset(xPos, paddingTop),
        Offset(xPos, paddingTop + plotHeight),
        gridPaint,
      );

      final xVal = (maxX * xRatio).toStringAsFixed(2);
      final textSpan = TextSpan(text: xVal, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, paddingTop + plotHeight + 6));
    }

    // Draw Main Axes
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + plotHeight),
      Offset(paddingLeft + plotWidth, paddingTop + plotHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + plotHeight),
      axisPaint,
    );

    // Axis Labels
    final xLabelPainter = TextPainter(
      text: TextSpan(
        text: '$xLabel ($xUnit)',
        style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelPainter.paint(
      canvas,
      Offset(paddingLeft + (plotWidth - xLabelPainter.width) / 2, size.height - 15),
    );

    // Draw curves
    for (final s in seriesList) {
      if (s.points.isEmpty) continue;

      final sortedPoints = List<PointData>.from(s.points)..sort((a, b) => a.x.compareTo(b.x));

      final linePaint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pointPaint = Paint()
        ..color = s.color
        ..style = PaintingStyle.fill;

      final path = Path();
      bool first = true;

      for (final p in sortedPoints) {
        final double px = paddingLeft + (p.x / maxX) * plotWidth;
        final double py = paddingTop + plotHeight * (1.0 - math.max(0.0, p.y / maxY));

        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          path.lineTo(px, py);
        }

        // Draw dot at each point
        canvas.drawCircle(Offset(px, py), 3.5, pointPaint);
        canvas.drawCircle(Offset(px, py), 1.5, Paint()..color = Colors.black);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BjtChartPainter oldDelegate) => true;
}
