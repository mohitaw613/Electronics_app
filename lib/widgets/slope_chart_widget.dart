import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/slope_measurement.dart';
import 'graph_widget.dart';

class SlopeChartWidget extends StatefulWidget {
  final String title;
  final String xLabel;
  final String yLabel;
  final String xUnit;
  final String yUnit;
  final List<CurveSeries> seriesList;
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;


  /// Mode for slope calculation
  final SlopeMode slopeMode;

  const SlopeChartWidget({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.seriesList,
    this.xUnit = 'V',
    this.yUnit = 'mA',
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.slopeMode = SlopeMode.inputResistance,
  });

  @override
  State<SlopeChartWidget> createState() => _SlopeChartWidgetState();
}

class _SlopeChartWidgetState extends State<SlopeChartWidget> {
  final TransformationController _transformController = TransformationController();
  bool _slopeToolEnabled = false;
  double _currentScale = 1.0;
  Offset? _slopePoint1;
  Offset? _slopePoint2;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _zoomIn() {
    final newScale = math.min(1.8, _currentScale + 0.25);
    setState(() {
      _currentScale = newScale;
      _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    });
  }

  void _zoomOut() {
    final newScale = math.max(0.70, _currentScale - 0.20);
    setState(() {
      _currentScale = newScale;
      _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  void _handleTap(
    Offset localPosition,
    Size chartSize,
    EdgeInsets padding,
    double curXMin,
    double curXMax,
    double curYMin,
    double curYMax,
  ) {
    if (!_slopeToolEnabled) return;

    final plotW = chartSize.width - padding.left - padding.right;
    final plotH = chartSize.height - padding.top - padding.bottom;

    if (localPosition.dx < padding.left ||
        localPosition.dx > padding.left + plotW ||
        localPosition.dy < padding.top ||
        localPosition.dy > padding.top + plotH) {
      return;
    }

    final double normX = (localPosition.dx - padding.left) / plotW;
    final double normY = (padding.top + plotH - localPosition.dy) / plotH;

    final double graphX = curXMin + normX * (curXMax - curXMin);
    final double graphY = curYMin + normY * (curYMax - curYMin);

    setState(() {
      if (_slopePoint1 == null) {
        _slopePoint1 = Offset(graphX, graphY);
      } else if (_slopePoint2 == null) {
        _slopePoint2 = Offset(graphX, graphY);
      } else {
        _slopePoint1 = Offset(graphX, graphY);
        _slopePoint2 = null;
      }
    });
  }

  void _clearSlopePoints() {
    setState(() {
      _slopePoint1 = null;
      _slopePoint2 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isInputCurve = widget.slopeMode == SlopeMode.inputResistance ||
        widget.xLabel.toLowerCase().contains('vbe') ||
        widget.yUnit.contains('µA') ||
        widget.yUnit.contains('uA');

    // Dynamic auto-scaling of axis bounds
    double rawMaxX = 0.0;
    double rawMaxY = 0.0;
    for (final s in widget.seriesList) {
      for (final p in s.points) {
        if (p.x > rawMaxX) rawMaxX = p.x;
        if (p.y > rawMaxY) rawMaxY = p.y;
      }
    }
    // Baseline minimum ranges
    if (isInputCurve) {
      rawMaxX = math.max(rawMaxX, 0.8);
      rawMaxY = math.max(rawMaxY, 20.0);
    } else {
      rawMaxX = math.max(rawMaxX, 10.0);
      rawMaxY = math.max(rawMaxY, 2.0);
    }

    final xMaxEffective = widget.xMax ?? (isInputCurve ? math.max(0.92, rawMaxX * 1.20) : math.max(12.0, rawMaxX * 1.18));
    final yMaxEffective = widget.yMax ?? (rawMaxY * 1.28);
    final xMinEffective = widget.xMin ?? 0.0;
    final yMinEffective = widget.yMin ?? 0.0;

    SlopeMeasurement? measurement;
    if (_slopePoint1 != null && _slopePoint2 != null) {
      measurement = SlopeMeasurement(
        point1: _slopePoint1!,
        point2: _slopePoint2!,
        mode: widget.slopeMode,
      );
    }

    final isZoomed = (_currentScale - 1.0).abs() > 0.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── TOP CONTROLS TOOLBAR (2-Row Overflow-Proof Layout) ──
        // Row 1: Title + Best-Fit Tag on left, Zoom Controls on right
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.teal, width: 0.8),
                    ),
                    child: const Text(
                      'Best-Fit',
                      style: TextStyle(color: Colors.teal, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Zoom Stepper Controls (ultra compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _currentScale > 0.75 ? _zoomOut : null,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.zoom_out, size: 16, color: _currentScale > 0.75 ? null : Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '${((_currentScale - 1.0) * 100).round()}%',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isZoomed ? Colors.purple : Colors.grey),
                    ),
                  ),
                  GestureDetector(
                    onTap: _currentScale < 1.78 ? _zoomIn : null,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.zoom_in, size: 16, color: _currentScale < 1.78 ? null : Colors.grey),
                    ),
                  ),
                  if (isZoomed) ...[
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: _resetZoom,
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.restart_alt, size: 14, color: Colors.purple),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Row 2: Slope Tool Toggle & Reset Points
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilterChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                Icons.straighten,
                size: 13,
                color: _slopeToolEnabled ? Colors.amber.shade900 : Colors.grey,
              ),
              label: Text(
                _slopeToolEnabled ? 'Slope Tool: ACTIVE' : 'Enable Slope Tool',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: _slopeToolEnabled ? Colors.amber.shade900 : null,
                ),
              ),
              selected: _slopeToolEnabled,
              selectedColor: Colors.amber.shade200,
              onSelected: (val) {
                setState(() {
                  _slopeToolEnabled = val;
                  if (!val) {
                    _slopePoint1 = null;
                    _slopePoint2 = null;
                  }
                });
              },
            ),
            if (_slopePoint1 != null || _slopePoint2 != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
                icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                label: const Text('Reset Points', style: TextStyle(fontSize: 11, color: Colors.red)),
                onPressed: _clearSlopePoints,
              ),
          ],
        ),

        // ── STATUS / INSTRUCTION BANNER ──
        if (measurement != null)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Text(
                      widget.slopeMode == SlopeMode.inputResistance
                          ? 'Input Resistance (R_in):'
                          : widget.slopeMode == SlopeMode.outputResistance
                              ? 'Output Resistance (R_out):'
                              : 'Current Gain (β):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Text(
                  measurement.formattedResult,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          )
        else if (_slopeToolEnabled)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade600, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Text(
                  _slopePoint1 == null
                      ? 'Slope Tool Active: Tap 1st point on curve'
                      : 'Tap 2nd point to complete slope triangle',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),


        // ── INTERACTIVE CANVAS WITH ZOOM (MAX 1.8X = +80%) ──
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const padding = EdgeInsets.fromLTRB(48, 14, 20, 34);
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.70, // Diszoom out down to 70%
                  maxScale: 1.8, // Controlled zoom: up to 80%
                  panEnabled: !_slopeToolEnabled, // Free pan when slope tool is off
                  scaleEnabled: true,
                  child: GestureDetector(
                    onTapDown: _slopeToolEnabled
                        ? (details) => _handleTap(
                              details.localPosition,
                              Size(constraints.maxWidth, constraints.maxHeight),
                              padding,
                              xMinEffective,
                              xMaxEffective,
                              yMinEffective,
                              yMaxEffective,
                            )
                        : null,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _IdealBestFitChartPainter(
                        seriesList: widget.seriesList,
                        xMin: xMinEffective,
                        xMax: xMaxEffective,
                        yMin: yMinEffective,
                        yMax: yMaxEffective,
                        xLabel: widget.xLabel,
                        yLabel: widget.yLabel,
                        xUnit: widget.xUnit,
                        yUnit: widget.yUnit,
                        padding: padding,
                        isDark: isDark,
                        isInputCurve: isInputCurve,
                        point1: _slopePoint1,
                        point2: _slopePoint2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── LEGEND ROW ──
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in widget.seriesList)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(s.name, style: const TextStyle(fontSize: 11)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ideal Shape Curve Fitting Mathematical Models
// ─────────────────────────────────────────────────────────────────────────────

/// Ideal Input Characteristic Model:
/// Monotonic convex diode equation: y = A * [ softplus((x - V0) / s) ]^gamma
/// Guaranteed: 0 below cut-in, smooth exponential knee, monotonic convex rise.
double Function(double) _fitIdealInputModel(List<PointData> points) {
  if (points.isEmpty) return (x) => 0.0;

  final ys = points.map((p) => p.y).toList();
  final maxY = ys.fold<double>(0.0, math.max);

  if (maxY <= 0) return (x) => 0.0;

  final nonZeroX = points.where((p) => p.y > 0.05 * maxY).map((p) => p.x).toList();
  final minActiveX = nonZeroX.isNotEmpty ? nonZeroX.reduce(math.min) : 0.65;

  double bestErr = double.infinity;
  double bestV0 = 0.65;
  double bestS = 0.03;
  double bestA = maxY;
  double bestGamma = 1.3;

  for (int v0Step = 0; v0Step <= 20; v0Step++) {
    final v0 = (minActiveX - 0.15) + 0.20 * (v0Step / 20.0);
    for (final s in [0.015, 0.03, 0.05]) {
      for (final gamma in [1.0, 1.3, 1.6]) {
        double num = 0.0;
        double den = 0.0;

        for (final p in points) {
          final u = (p.x - v0) / s;
          double basis;
          if (u > 40) {
            basis = p.x - v0;
          } else if (u < -40) {
            basis = 0.0;
          } else {
            basis = s * math.log(1.0 + math.exp(u));
          }
          final val = math.pow(math.max(0.0, basis), gamma).toDouble();
          num += val * p.y;
          den += val * val;
        }

        final A = den > 1e-9 ? math.max(0.0, num / den) : 0.0;

        double err = 0.0;
        for (final p in points) {
          final u = (p.x - v0) / s;
          double basis;
          if (u > 40) {
            basis = p.x - v0;
          } else if (u < -40) {
            basis = 0.0;
          } else {
            basis = s * math.log(1.0 + math.exp(u));
          }
          final pred = A * math.pow(math.max(0.0, basis), gamma).toDouble();
          err += (pred - p.y) * (pred - p.y);
        }

        if (err < bestErr) {
          bestErr = err;
          bestV0 = v0;
          bestS = s;
          bestA = A;
          bestGamma = gamma;
        }
      }
    }
  }

  return (double x) {
    if (x <= 0) return 0.0;
    final u = (x - bestV0) / bestS;
    if (u < -40) return 0.0;
    double basis;
    if (u > 40) {
      basis = x - bestV0;
    } else {
      basis = bestS * math.log(1.0 + math.exp(u));
    }
    return bestA * math.pow(math.max(0.0, basis), bestGamma).toDouble();
  };
}

/// Ideal Output Characteristic Model:
/// Saturation-Active equation: y = Isat * (1 - exp(-x / Vk)) + m * x
/// Guaranteed: starts at (0,0), steep saturation rise, smooth knee,
/// flat/gently-sloping active plateau. Monotonic and concave downwards.
double Function(double) _fitIdealOutputModel(List<PointData> points) {
  if (points.isEmpty) return (x) => 0.0;

  final xs = points.map((p) => p.x).toList();
  final ys = points.map((p) => p.y).toList();
  final maxX = xs.fold<double>(0.0, math.max);
  final maxY = ys.fold<double>(0.0, math.max);

  if (maxY <= 0) return (x) => 0.0;

  double bestErr = double.infinity;
  double bestIsat = maxY;
  double bestVk = 0.25;
  double bestM = 0.01;

  final effMaxX = math.max(1.0, maxX);
  for (int step = 1; step <= 35; step++) {
    final vk = math.max(0.02, (effMaxX * 0.15) * (step / 30.0));

    double s11 = 0.0, s12 = 0.0, s22 = 0.0, t1 = 0.0, t2 = 0.0;
    for (final p in points) {
      final f1 = 1.0 - math.exp(-p.x / vk);
      final f2 = p.x;
      s11 += f1 * f1;
      s12 += f1 * f2;
      s22 += f2 * f2;
      t1 += f1 * p.y;
      t2 += f2 * p.y;
    }

    final det = s11 * s22 - s12 * s12;
    double isat = maxY;
    double m = 0.0;
    if (det.abs() > 1e-9) {
      isat = math.max(0.0, (s22 * t1 - s12 * t2) / det);
      m = math.max(0.0, (s11 * t2 - s12 * t1) / det);
    }

    double err = 0.0;
    for (final p in points) {
      final pred = isat * (1.0 - math.exp(-p.x / vk)) + m * p.x;
      err += (pred - p.y) * (pred - p.y);
    }

    if (err < bestErr) {
      bestErr = err;
      bestIsat = isat;
      bestVk = vk;
      bestM = m;
    }
  }

  return (double x) {
    if (x <= 0) return 0.0;
    return bestIsat * (1.0 - math.exp(-x / bestVk)) + bestM * x;
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart Painter
// ─────────────────────────────────────────────────────────────────────────────

class _IdealBestFitChartPainter extends CustomPainter {
  final List<CurveSeries> seriesList;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final String xLabel;
  final String yLabel;
  final String xUnit;
  final String yUnit;
  final EdgeInsets padding;
  final bool isDark;
  final bool isInputCurve;
  final Offset? point1;
  final Offset? point2;

  _IdealBestFitChartPainter({
    required this.seriesList,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xLabel,
    required this.yLabel,
    required this.xUnit,
    required this.yUnit,
    required this.padding,
    required this.isDark,
    required this.isInputCurve,
    this.point1,
    this.point2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - padding.left - padding.right;
    final plotH = size.height - padding.top - padding.bottom;
    if (plotW <= 0 || plotH <= 0) return;

    Offset toPixel(double gx, double gy) {
      final nx = (gx - xMin) / (xMax - xMin);
      final ny = (gy - yMin) / (yMax - yMin);
      final px = padding.left + nx.clamp(-0.1, 1.1) * plotW;
      final py = padding.top + (1.0 - ny.clamp(-0.1, 1.1)) * plotH;
      return Offset(px, py);
    }

    // Grid lines & Axes
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = isDark ? Colors.white60 : Colors.black54
      ..strokeWidth = 1.4;

    const int xDivs = 5;
    for (int i = 0; i <= xDivs; i++) {
      final gx = xMin + (xMax - xMin) * (i / xDivs);
      final px = padding.left + (i / xDivs) * plotW;
      canvas.drawLine(Offset(px, padding.top), Offset(px, padding.top + plotH), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: gx.toStringAsFixed(gx < 2 ? (gx < 0.2 ? 2 : 1) : 0),
          style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, padding.top + plotH + 4));
    }

    const int yDivs = 5;
    for (int i = 0; i <= yDivs; i++) {
      final gy = yMin + (yMax - yMin) * (i / yDivs);
      final py = padding.top + (1.0 - (i / yDivs)) * plotH;
      canvas.drawLine(Offset(padding.left, py), Offset(padding.left + plotW, py), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: gy >= 1000 ? '${(gy / 1000).toStringAsFixed(1)}k' : gy.toStringAsFixed(gy < 2 ? 1 : 0),
          style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding.left - tp.width - 6, py - tp.height / 2));
    }

    // Axes
    canvas.drawLine(Offset(padding.left, padding.top), Offset(padding.left, padding.top + plotH), axisPaint);
    canvas.drawLine(Offset(padding.left, padding.top + plotH), Offset(padding.left + plotW, padding.top + plotH), axisPaint);

    // Axis Labels
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white70 : Colors.black87,
    );
    final xTp = TextPainter(
      text: TextSpan(text: '$xLabel ($xUnit)', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    xTp.paint(canvas, Offset(padding.left + plotW / 2 - xTp.width / 2, padding.top + plotH + 18));

    canvas.save();
    canvas.translate(12, padding.top + plotH / 2);
    canvas.rotate(-math.pi / 2);
    final yTp = TextPainter(
      text: TextSpan(text: '$yLabel ($yUnit)', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    yTp.paint(canvas, Offset(-yTp.width / 2, 0));
    canvas.restore();

    // ─────────────────────────────────────────────────────────────
    // Render Curves with Ideal Physical Shape Fitting
    // ─────────────────────────────────────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(padding.left, padding.top, plotW, plotH));

    for (final series in seriesList) {
      if (series.points.isEmpty) continue;

      // Fit the ideal physical model
      final model = isInputCurve
          ? _fitIdealInputModel(series.points)
          : _fitIdealOutputModel(series.points);

      // Render smooth continuous ideal curve with 150 dense samples
      const sampleCount = 150;
      final curvePath = Path();
      final fillPath = Path();
      bool first = true;

      for (int i = 0; i <= sampleCount; i++) {
        final gx = xMin + (xMax - xMin) * (i / sampleCount);
        final gy = model(gx);
        final pt = toPixel(gx, gy);

        if (first) {
          curvePath.moveTo(pt.dx, pt.dy);
          fillPath.moveTo(pt.dx, padding.top + plotH);
          fillPath.lineTo(pt.dx, pt.dy);
          first = false;
        } else {
          curvePath.lineTo(pt.dx, pt.dy);
          fillPath.lineTo(pt.dx, pt.dy);
        }
      }
      fillPath.lineTo(toPixel(xMax, 0).dx, padding.top + plotH);
      fillPath.close();

      // Subtle fill
      canvas.drawPath(
        fillPath,
        Paint()..color = series.color.withValues(alpha: 0.08)..style = PaintingStyle.fill,
      );

      // Smooth best-fit line
      canvas.drawPath(
        curvePath,
        Paint()
          ..color = series.color
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Render actual student scatter points as clearly defined markers
      for (final p in series.points) {
        final pix = toPixel(p.x, p.y);

        // Halo
        canvas.drawCircle(
          pix,
          5.0,
          Paint()
            ..color = series.color.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        // Center dot
        canvas.drawCircle(
          pix,
          2.5,
          Paint()
            ..color = series.color
            ..style = PaintingStyle.fill,
        );
      }
    }

    // ─────────────────────────────────────────────────────────────
    // Slope Triangle
    // ─────────────────────────────────────────────────────────────
    if (point1 != null && point2 != null) {
      final p1 = toPixel(point1!.dx, point1!.dy);
      final p2 = toPixel(point2!.dx, point2!.dy);
      final corner = Offset(p2.dx, p1.dy);

      final triPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(
        triPath,
        Paint()..color = Colors.amber.withValues(alpha: 0.18)..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        triPath,
        Paint()..color = Colors.amber.shade700..strokeWidth = 2.0..style = PaintingStyle.stroke,
      );

      final dxVal = (point2!.dx - point1!.dx).abs();
      final dyVal = (point2!.dy - point1!.dy).abs();

      final dxTp = TextPainter(
        text: TextSpan(
          text: 'ΔV=${dxVal.toStringAsFixed(2)}$xUnit',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dxTp.paint(canvas, Offset((p1.dx + corner.dx) / 2 - dxTp.width / 2, corner.dy + 3));

      final dyTp = TextPainter(
        text: TextSpan(
          text: 'ΔI=${dyVal.toStringAsFixed(2)}$yUnit',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dyTp.paint(canvas, Offset(corner.dx + 4, (corner.dy + p2.dy) / 2 - dyTp.height / 2));
    }

    // Markers on tap points
    if (point1 != null) {
      final p = toPixel(point1!.dx, point1!.dy);
      canvas.drawCircle(p, 5.0, Paint()..color = Colors.amber.shade800);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
    if (point2 != null) {
      final p = toPixel(point2!.dx, point2!.dy);
      canvas.drawCircle(p, 5.0, Paint()..color = Colors.amber.shade800);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IdealBestFitChartPainter oldDelegate) => true;
}
