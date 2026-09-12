import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public Data Models
// ─────────────────────────────────────────────────────────────────────────────

class PointData {
  final double x;
  final double y;
  const PointData(this.x, this.y);
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

// ─────────────────────────────────────────────────────────────────────────────
//  Desmos-Style Scientific Chart Widget
// ─────────────────────────────────────────────────────────────────────────────

class BjtCurveChart extends StatefulWidget {
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
  State<BjtCurveChart> createState() => _BjtCurveChartState();
}

class _BjtCurveChartState extends State<BjtCurveChart> {
  Offset? _hoverPoint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPoints = widget.seriesList.fold<int>(0, (sum, s) => sum + s.points.length);
    final hasData = totalPoints > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? cs.outline.withValues(alpha: 0.25) : const Color(0xFFCCCCCC),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar (Overflow-Proof)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? cs.outline.withValues(alpha: 0.2) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? cs.onSurface : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.teal.shade900.withValues(alpha: 0.5) : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isDark ? Colors.tealAccent.withValues(alpha: 0.4) : Colors.teal.shade200),
                      ),
                      child: Text(
                        'Best-Fit',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark ? Colors.tealAccent : Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: widget.seriesList.map((s) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: s.color, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.name,
                          style: TextStyle(
                            color: s.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Plot Area
          Expanded(
            child: hasData
                ? GestureDetector(
                    onPanUpdate: (d) => setState(() => _hoverPoint = d.localPosition),
                    onPanEnd: (_) => setState(() => _hoverPoint = null),
                    onTapUp: (d) => setState(() => _hoverPoint = d.localPosition),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
                      child: CustomPaint(
                        painter: _DesmosChartPainter(
                          seriesList: widget.seriesList,
                          xLabel: widget.xLabel,
                          yLabel: widget.yLabel,
                          xUnit: widget.xUnit,
                          yUnit: widget.yUnit,
                          hoverPoint: _hoverPoint,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_graph, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No observations entered yet.\nEnter readings in the table to plot the continuous curve.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11.5, height: 1.4),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Scientific Curve Fitting Helpers
// ─────────────────────────────────────────────────────────────────────────────

double _evaluateBestFit(List<PointData> pts, double x, bool isInputCurve) {
  if (pts.isEmpty) return 0.0;
  if (pts.length == 1) return pts.first.y;

  if (isInputCurve) {
    // Softplus diode knee model: y = slope * s * ln(1 + exp((x - V0) / s))
    final nonZero = pts.where((p) => p.y > 0).toList();
    final minNonZeroX = nonZero.isNotEmpty ? nonZero.map((p) => p.x).reduce(math.min) : 0.65;

    double bestErr = double.infinity;
    double bestV0 = minNonZeroX - 0.02;
    double bestS = 0.006;
    double bestSlope = 50000.0;

    for (int step = 0; step <= 25; step++) {
      final v0 = (minNonZeroX - 0.06) + 0.08 * (step / 25.0);
      const s = 0.006;

      double num = 0.0, den = 0.0;
      for (final p in pts) {
        final u = (p.x - v0) / s;
        final f = u > 40 ? (p.x - v0) : (u < -40 ? 0.0 : s * math.log(1.0 + math.exp(u)));
        num += f * p.y;
        den += f * f;
      }
      final slope = den > 1e-12 ? math.max(0.0, num / den) : 0.0;

      double err = 0.0;
      for (final p in pts) {
        final u = (p.x - v0) / s;
        final f = u > 40 ? (p.x - v0) : (u < -40 ? 0.0 : s * math.log(1.0 + math.exp(u)));
        final diff = slope * f - p.y;
        err += diff * diff;
      }

      if (err < bestErr) {
        bestErr = err;
        bestV0 = v0;
        bestS = s;
        bestSlope = slope;
      }
    }

    final u = (x - bestV0) / bestS;
    if (u < -40) return 0.0;
    if (u > 40) return math.max(0.0, bestSlope * (x - bestV0));
    return math.max(0.0, bestSlope * bestS * math.log(1.0 + math.exp(u)));
  } else {
    // Output characteristic model: y = Isat * (1 - exp(-x / Vk)) + m * x
    final maxX = pts.map((p) => p.x).reduce(math.max);
    final maxY = pts.map((p) => p.y).reduce(math.max);

    double bestErr = double.infinity;
    double bestIsat = maxY;
    double bestVk = 0.1;
    double bestM = 0.0;

    for (int step = 1; step <= 35; step++) {
      final vk = math.max(0.01, (maxX * 0.12) * (step / 20.0));

      double s11 = 0.0, s12 = 0.0, s22 = 0.0, t1 = 0.0, t2 = 0.0;
      for (final p in pts) {
        final f1 = 1.0 - math.exp(-p.x / vk);
        final f2 = p.x;
        s11 += f1 * f1;
        s12 += f1 * f2;
        s22 += f2 * f2;
        t1 += f1 * p.y;
        t2 += f2 * p.y;
      }

      final det = s11 * s22 - s12 * s12;
      double isat = maxY, m = 0.0;
      if (det.abs() > 1e-9) {
        isat = math.max(0.0, (s22 * t1 - s12 * t2) / det);
        m = math.max(0.0, (s11 * t2 - s12 * t1) / det);
      }

      double err = 0.0;
      for (final p in pts) {
        final f1 = 1.0 - math.exp(-p.x / vk);
        final pred = isat * f1 + m * p.x;
        final diff = pred - p.y;
        err += diff * diff;
      }

      if (err < bestErr) {
        bestErr = err;
        bestIsat = isat;
        bestVk = vk;
        bestM = m;
      }
    }

    if (x <= 0.0) return 0.0;
    return math.max(0.0, bestIsat * (1.0 - math.exp(-x / bestVk)) + bestM * x);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Axis Calculations
// ─────────────────────────────────────────────────────────────────────────────

({double niceMax, double step, int count}) _niceAxis(double rawMax, {int targetTicks = 5}) {
  if (rawMax <= 0) rawMax = 1.0;
  final exp = (math.log(rawMax) / math.ln10).floor();
  final magnitude = math.pow(10, exp).toDouble();
  final normalized = rawMax / magnitude;

  double niceNorm;
  if (normalized <= 1.0) {
    niceNorm = 1.0;
  } else if (normalized <= 2.0) {
    niceNorm = 2.0;
  } else if (normalized <= 5.0) {
    niceNorm = 5.0;
  } else {
    niceNorm = 10.0;
  }

  final niceMax = niceNorm * magnitude;
  return (niceMax: niceMax, step: niceMax / targetTicks, count: targetTicks);
}

String _formatTick(double v, double step) {
  if (v == 0) return '0';
  if (step >= 10) return v.toStringAsFixed(0);
  if (step >= 1) return v.toStringAsFixed(1);
  if (step >= 0.1) return v.toStringAsFixed(2);
  if (step >= 0.01) return v.toStringAsFixed(3);
  return v.toStringAsExponential(2);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Desmos Chart Painter — Continuous Smooth Line over Dots
// ─────────────────────────────────────────────────────────────────────────────

class _DesmosChartPainter extends CustomPainter {
  final List<CurveSeries> seriesList;
  final String xLabel;
  final String yLabel;
  final String xUnit;
  final String yUnit;
  final Offset? hoverPoint;
  final bool isDark;

  static const double _padLeft = 58.0;
  static const double _padBottom = 44.0;
  static const double _padTop = 16.0;
  static const double _padRight = 14.0;

  const _DesmosChartPainter({
    required this.seriesList,
    required this.xLabel,
    required this.yLabel,
    required this.xUnit,
    required this.yUnit,
    this.hoverPoint,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padLeft - _padRight;
    final plotH = size.height - _padTop - _padBottom;
    if (plotW <= 0 || plotH <= 0) return;

    final isInput = xLabel.contains('VBE') || yUnit == 'µA';

    double rawMaxX = 0, rawMaxY = 0;
    for (final s in seriesList) {
      for (final p in s.points) {
        if (p.x > rawMaxX) rawMaxX = p.x;
        if (p.y > rawMaxY) rawMaxY = p.y;
      }
    }
    if (rawMaxX == 0) rawMaxX = 1.0;
    if (rawMaxY == 0) rawMaxY = 1.0;

    final xAxis = _niceAxis(rawMaxX * 1.05);
    final yAxis = _niceAxis(rawMaxY * 1.08);
    final maxX = xAxis.niceMax;
    final maxY = yAxis.niceMax;

    double toCanvasX(double d) => _padLeft + (d / maxX) * plotW;
    double toCanvasY(double d) => _padTop + plotH * (1.0 - (d / maxY).clamp(0.0, 1.15));
    double fromCanvasX(double cx) => ((cx - _padLeft) / plotW) * maxX;
    double fromCanvasY(double cy) => (((_padTop + plotH) - cy) / plotH) * maxY;

    final plotRect = Rect.fromLTWH(_padLeft, _padTop, plotW, plotH);

    // 1. Chart Background
    canvas.drawRect(
      plotRect,
      Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white,
    );

    // 2. Minor Grid
    final minorGrid = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= xAxis.count * 2; i++) {
      final v = (xAxis.step / 2) * i;
      if (v > maxX) break;
      final cx = toCanvasX(v);
      canvas.drawLine(Offset(cx, _padTop), Offset(cx, _padTop + plotH), minorGrid);
    }
    for (int i = 0; i <= yAxis.count * 2; i++) {
      final v = (yAxis.step / 2) * i;
      if (v > maxY) break;
      final cy = toCanvasY(v);
      canvas.drawLine(Offset(_padLeft, cy), Offset(_padLeft + plotW, cy), minorGrid);
    }

    // 3. Major Grid
    final majorGrid = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= xAxis.count; i++) {
      final cx = toCanvasX(xAxis.step * i);
      canvas.drawLine(Offset(cx, _padTop), Offset(cx, _padTop + plotH), majorGrid);
    }
    for (int i = 0; i <= yAxis.count; i++) {
      final cy = toCanvasY(yAxis.step * i);
      canvas.drawLine(Offset(_padLeft, cy), Offset(_padLeft + plotW, cy), majorGrid);
    }

    // 4. Main Axes & Arrows
    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF374151)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(_padLeft, _padTop + plotH),
      Offset(_padLeft + plotW + 8, _padTop + plotH),
      axisPaint,
    );
    canvas.drawLine(
      Offset(_padLeft, _padTop + plotH),
      Offset(_padLeft, _padTop - 8),
      axisPaint,
    );

    void drawArrow(Offset tip, bool isHorizontal) {
      final path = Path();
      if (isHorizontal) {
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx - 7, tip.dy - 3.5);
        path.lineTo(tip.dx - 7, tip.dy + 3.5);
      } else {
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(tip.dx - 3.5, tip.dy + 7);
        path.lineTo(tip.dx + 3.5, tip.dy + 7);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF374151)
          ..style = PaintingStyle.fill,
      );
    }

    drawArrow(Offset(_padLeft + plotW + 8, _padTop + plotH), true);
    drawArrow(Offset(_padLeft, _padTop - 8), false);

    // 5. Numerical Tick Labels
    final tickStyle = TextStyle(
      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
      fontSize: 9.5,
      fontFamily: 'monospace',
    );

    for (int i = 0; i <= xAxis.count; i++) {
      final v = xAxis.step * i;
      final cx = toCanvasX(v);
      canvas.drawLine(Offset(cx, _padTop + plotH - 3.5), Offset(cx, _padTop + plotH + 3.5), axisPaint);
      _drawText(canvas, _formatTick(v, xAxis.step), Offset(cx, _padTop + plotH + 11), tickStyle, center: true);
    }
    for (int i = 0; i <= yAxis.count; i++) {
      final v = yAxis.step * i;
      final cy = toCanvasY(v);
      canvas.drawLine(Offset(_padLeft - 3.5, cy), Offset(_padLeft + 3.5, cy), axisPaint);
      _drawText(canvas, _formatTick(v, yAxis.step), Offset(_padLeft - 6, cy), tickStyle, rightAlign: true);
    }

    // 6. Axis Titles
    final labelStyle = TextStyle(
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827),
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
    );
    _drawText(canvas, '$xLabel  ($xUnit)', Offset(_padLeft + plotW / 2, size.height - 4), labelStyle, center: true);

    canvas.save();
    canvas.translate(11, _padTop + plotH / 2);
    canvas.rotate(-math.pi / 2);
    _drawText(canvas, '$yLabel  ($yUnit)', Offset.zero, labelStyle, center: true);
    canvas.restore();

    // 7. Render Curves & Scatter Dots (CONTINUOUS: dots first, curve ON TOP without opaque white mask)
    canvas.save();
    canvas.clipRect(plotRect);

    for (final s in seriesList) {
      if (s.points.isEmpty) continue;

      // STEP A: Render Scatter Dots First (transparent ring + center dot, NO opaque white fill to cut the curve!)
      for (final p in s.points) {
        final cx = toCanvasX(p.x);
        final cy = toCanvasY(p.y);

        // Soft outer halo ring (stroke only, so curve line remains fully visible!)
        canvas.drawCircle(
          Offset(cx, cy),
          5.0,
          Paint()
            ..color = s.color.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        // Center point marker
        canvas.drawCircle(
          Offset(cx, cy),
          2.0,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.fill,
        );
      }

      // STEP B: Render Continuous Best-Fit Curve ON TOP of dots
      if (s.points.length >= 2) {
        const sampleCount = 200; // Dense sampling ensures completely continuous curve
        final curvePath = Path();
        final fillPath = Path();

        bool isFirst = true;
        for (int i = 0; i <= sampleCount; i++) {
          final sampleX = (maxX * i) / sampleCount;
          final sampleY = _evaluateBestFit(s.points, sampleX, isInput);
          final cx = toCanvasX(sampleX);
          final cy = toCanvasY(sampleY);

          if (isFirst) {
            curvePath.moveTo(cx, cy);
            fillPath.moveTo(cx, _padTop + plotH);
            fillPath.lineTo(cx, cy);
            isFirst = false;
          } else {
            curvePath.lineTo(cx, cy);
            fillPath.lineTo(cx, cy);
          }
        }
        fillPath.lineTo(toCanvasX(maxX), _padTop + plotH);
        fillPath.close();

        // Subtle fill under curve
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = s.color.withValues(alpha: 0.07)
            ..style = PaintingStyle.fill,
        );

        // Continuous smooth stroke passes over dots without any break or cut
        canvas.drawPath(
          curvePath,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    canvas.restore();

    // 8. Interactive Hover Crosshair & Coordinate Tooltip
    if (hoverPoint != null && plotRect.contains(hoverPoint!)) {
      final hx = hoverPoint!.dx;
      final hy = hoverPoint!.dy;
      final dashPaint = Paint()
        ..color = const Color(0xFF6B7280)
        ..strokeWidth = 0.8;

      _drawDashedLine(canvas, Offset(hx, _padTop), Offset(hx, _padTop + plotH), dashPaint);
      _drawDashedLine(canvas, Offset(_padLeft, hy), Offset(_padLeft + plotW, hy), dashPaint);

      // Highlight nearest scatter point
      double minDist = double.infinity;
      PointData? closestPoint;
      Color closestColor = Colors.grey;

      for (final s in seriesList) {
        for (final p in s.points) {
          final dist = math.sqrt(math.pow(toCanvasX(p.x) - hx, 2) + math.pow(toCanvasY(p.y) - hy, 2));
          if (dist < minDist) {
            minDist = dist;
            closestPoint = p;
            closestColor = s.color;
          }
        }
      }

      if (closestPoint != null && minDist < 32) {
        final cx = toCanvasX(closestPoint.x);
        final cy = toCanvasY(closestPoint.y);
        canvas.drawCircle(
          Offset(cx, cy),
          8.0,
          Paint()
            ..color = closestColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      final dataX = fromCanvasX(hx);
      final dataY = fromCanvasY(hy);
      final coordText = '(${_formatTick(dataX, xAxis.step)} $xUnit,  ${_formatTick(dataY, yAxis.step)} $yUnit)';

      final tp = TextPainter(
        text: TextSpan(
          text: coordText,
          style: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double tx = hx + 8, ty = hy - 24;
      if (tx + tp.width + 12 > _padLeft + plotW) tx = hx - tp.width - 12;
      if (ty < _padTop + 4) ty = hy + 8;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tx - 4, ty - 3, tp.width + 8, tp.height + 6),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      tp.paint(canvas, Offset(tx, ty));
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style, {
    bool center = false,
    bool rightAlign = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = pos.dx, dy = pos.dy - tp.height / 2;
    if (center) dx -= tp.width / 2;
    if (rightAlign) dx -= tp.width;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint p) {
    const dash = 4.0, gap = 4.0;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final ux = dx / dist, uy = dy / dist;
    double t = 0;
    bool draw = true;
    while (t < dist) {
      final len = draw ? dash : gap;
      final next = math.min(t + len, dist);
      if (draw) {
        canvas.drawLine(Offset(a.dx + ux * t, a.dy + uy * t), Offset(a.dx + ux * next, a.dy + uy * next), p);
      }
      t = next;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _DesmosChartPainter old) => true;
}
