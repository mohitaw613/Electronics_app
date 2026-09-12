import 'package:flutter/material.dart';

/// Proteus-style CAD Circuit Schematic Widget for BJT Common Emitter (Experiment 5).
/// Features real-time animated current flow, live digital voltmeter/ammeter probes,
/// and standard schematic symbols matching lab manual pages 17 & 18.
class ProteusBjtCircuit extends StatefulWidget {
  final double vbb; // Base supply voltage in Volts
  final double vcc; // Collector supply voltage in Volts
  final double rb; // Base resistor in kΩ
  final double rc; // Collector resistor in kΩ
  final double vbe; // Measured Base-Emitter voltage in Volts
  final double vce; // Measured Collector-Emitter voltage in Volts
  final double ib; // Base current in µA
  final double ic; // Collector current in mA
  final String region; // Operating region string

  const ProteusBjtCircuit({
    super.key,
    required this.vbb,
    required this.vcc,
    required this.rb,
    required this.rc,
    required this.vbe,
    required this.vce,
    required this.ib,
    required this.ic,
    required this.region,
  });

  @override
  State<ProteusBjtCircuit> createState() => _ProteusBjtCircuitState();
}

class _ProteusBjtCircuitState extends State<ProteusBjtCircuit> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: const Color(0xFF07141E), // Proteus dark CAD blue background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1B4965), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Schematic Canvas with animated current particles
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ProteusSchematicPainter(
                  animProgress: _animController.value,
                  vbb: widget.vbb,
                  vcc: widget.vcc,
                  rb: widget.rb,
                  rc: widget.rc,
                  vbe: widget.vbe,
                  vce: widget.vce,
                  ib: widget.ib,
                  ic: widget.ic,
                ),
              );
            },
          ),
          // Proteus CAD Header Banner
          Positioned(
            top: 8,
            left: 10,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003554),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'PROTEUS VSM CAD • SCHEMATIC',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EXP-5: BJT CE (BC547 NPN)',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProteusSchematicPainter extends CustomPainter {
  final double animProgress;
  final double vbb;
  final double vcc;
  final double rb;
  final double rc;
  final double vbe;
  final double vce;
  final double ib;
  final double ic;

  _ProteusSchematicPainter({
    required this.animProgress,
    required this.vbb,
    required this.vcc,
    required this.rb,
    required this.rc,
    required this.vbe,
    required this.vce,
    required this.ib,
    required this.ic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    // Key Coordinates in Schematic Layout
    final double midY = size.height * 0.50;
    final double topY = size.height * 0.18;
    final double bottomY = size.height * 0.85;

    final double vbbX = size.width * 0.08;
    final double rbX = size.width * 0.22;
    final double ammeterBX = size.width * 0.36;
    final double bjtBaseX = size.width * 0.48;

    final double bjtCenterX = size.width * 0.52;
    final double bjtCollectorY = midY - 28;
    final double bjtEmitterY = midY + 28;

    final double ammeterCX = size.width * 0.66;
    final double rcX = size.width * 0.78;
    final double vccX = size.width * 0.90;

    final wirePaint = Paint()
      ..color = const Color(0xFF00E5FF) // Proteus cyan wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final groundPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 1. Draw Wires - Input Loop (Left)
    final inputLoop = Path()
      ..moveTo(vbbX, bottomY)
      ..lineTo(vbbX, midY)
      ..lineTo(rbX - 18, midY); // to Rb left
    canvas.drawPath(inputLoop, wirePaint);

    // Rb right to Ammeter B
    canvas.drawLine(Offset(rbX + 18, midY), Offset(ammeterBX - 14, midY), wirePaint);
    // Ammeter B to BJT Base
    canvas.drawLine(Offset(ammeterBX + 14, midY), Offset(bjtBaseX, midY), wirePaint);

    // 2. Draw Wires - Output Loop (Right)
    final outputLoop = Path()
      ..moveTo(vccX, bottomY)
      ..lineTo(vccX, topY)
      ..lineTo(rcX + 18, topY); // to Rc right
    canvas.drawPath(outputLoop, wirePaint);

    // Rc left to Ammeter C
    canvas.drawLine(Offset(rcX - 18, topY), Offset(ammeterCX + 14, topY), wirePaint);
    // Ammeter C to Collector
    final collectorPath = Path()
      ..moveTo(ammeterCX - 14, topY)
      ..lineTo(bjtCenterX, topY)
      ..lineTo(bjtCenterX, bjtCollectorY);
    canvas.drawPath(collectorPath, wirePaint);

    // 3. Emitter to Ground Rail
    canvas.drawLine(Offset(bjtCenterX, bjtEmitterY), Offset(bjtCenterX, bottomY), wirePaint);

    // Common Ground Rail along bottom connecting Vbb, Emitter, and Vcc
    final gndRail = Path()
      ..moveTo(vbbX, bottomY)
      ..lineTo(vccX, bottomY);
    canvas.drawPath(gndRail, wirePaint);

    // 4. Draw Components
    // DC Source Vbb (Left)
    _drawDcSource(canvas, Offset(vbbX, midY + 15), 'V1 (Vbb)', '${vbb.toStringAsFixed(1)}V');

    // Base Resistor R1/Rb
    _drawResistor(canvas, Offset(rbX, midY), 'R1 (Rb)', '${rb.toStringAsFixed(0)}kΩ', isHorizontal: true);

    // Base Ammeter (Ib in µA)
    _drawMeter(canvas, Offset(ammeterBX, midY), 'mA', '${ib.toStringAsFixed(1)}µA', Colors.amberAccent);

    // Base-Emitter Voltmeter (Vbe)
    _drawVoltmeter(canvas, Offset(size.width * 0.42, bottomY - 30), 'VBE', '${vbe.toStringAsFixed(3)}V');

    // BJT Transistor Q1 (BC547 NPN)
    _drawBjtNpn(canvas, Offset(bjtCenterX, midY));

    // Collector-Emitter Voltmeter (Vce)
    _drawVoltmeter(canvas, Offset(size.width * 0.60, bottomY - 30), 'VCE', '${vce.toStringAsFixed(2)}V');

    // Collector Ammeter (Ic in mA)
    _drawMeter(canvas, Offset(ammeterCX, topY), 'mA', '${ic.toStringAsFixed(2)}mA', Colors.greenAccent);

    // Collector Resistor R2/Rc
    _drawResistor(canvas, Offset(rcX, topY), 'R2 (Rc)', '${rc.toStringAsFixed(1)}kΩ', isHorizontal: true);

    // DC Source Vcc (Right)
    _drawDcSource(canvas, Offset(vccX, midY), 'V2 (Vcc)', '${vcc.toStringAsFixed(1)}V');

    // Ground Symbol (GND at Emitter)
    _drawGndSymbol(canvas, Offset(bjtCenterX, bottomY), groundPaint);

    // 5. Draw Animated Current Flow Particles
    _drawCurrentFlow(canvas, size, midY, topY, bottomY, vbbX, bjtCenterX, vccX);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF0E2738)
      ..strokeWidth = 0.8;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawBjtNpn(Canvas canvas, Offset center) {
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Transistor Circle
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0xFF003554).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Base Bar (vertical)
    final double bx = center.dx - 8;
    canvas.drawLine(Offset(bx, center.dy - 16), Offset(bx, center.dy + 16), bodyPaint..strokeWidth = 3.5);

    // Base Lead
    canvas.drawLine(Offset(bx - 12, center.dy), Offset(bx, center.dy), bodyPaint..strokeWidth = 2.0);

    // Collector Slanted Line
    canvas.drawLine(Offset(bx, center.dy - 6), Offset(center.dx + 12, center.dy - 20), bodyPaint);
    canvas.drawLine(Offset(center.dx + 12, center.dy - 20), Offset(center.dx + 12, center.dy - 28), bodyPaint);

    // Emitter Slanted Line with Arrow
    final eStart = Offset(bx, center.dy + 6);
    final eEnd = Offset(center.dx + 12, center.dy + 20);
    canvas.drawLine(eStart, eEnd, bodyPaint);
    canvas.drawLine(eEnd, Offset(center.dx + 12, center.dy + 28), bodyPaint);

    // Emitter Arrow (pointing out for NPN)
    final arrowPath = Path()
      ..moveTo(eEnd.dx, eEnd.dy)
      ..lineTo(eEnd.dx - 7, eEnd.dy - 2)
      ..lineTo(eEnd.dx - 3, eEnd.dy - 7)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Component Label
    _drawText(canvas, Offset(center.dx - 18, center.dy - 36), 'Q1 (BC547)', color: Colors.cyanAccent, fontSize: 9);
    _drawText(canvas, Offset(bx - 10, center.dy - 12), 'B', color: Colors.grey, fontSize: 8);
    _drawText(canvas, Offset(center.dx + 14, center.dy - 22), 'C', color: Colors.grey, fontSize: 8);
    _drawText(canvas, Offset(center.dx + 14, center.dy + 16), 'E', color: Colors.grey, fontSize: 8);
  }

  void _drawResistor(Canvas canvas, Offset center, String name, String value, {bool isHorizontal = true}) {
    final rPaint = Paint()
      ..color = const Color(0xFFFFB703) // Proteus component yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const double w = 24.0;
    const double h = 10.0;

    final rect = Rect.fromCenter(center: center, width: isHorizontal ? w : h, height: isHorizontal ? h : w);
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF0B2538)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(rect, rPaint);

    _drawText(canvas, Offset(center.dx - 18, center.dy - 18), name, color: const Color(0xFFFFB703), fontSize: 8);
    _drawText(canvas, Offset(center.dx - 14, center.dy + 10), value, color: Colors.white70, fontSize: 8);
  }

  void _drawMeter(Canvas canvas, Offset center, String unit, String reading, Color color) {
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = const Color(0xFF0F3047)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawText(canvas, Offset(center.dx - 5, center.dy - 6), 'A', color: Colors.white, fontSize: 10, isBold: true);
    _drawText(canvas, Offset(center.dx - 18, center.dy + 15), reading, color: color, fontSize: 8, isBold: true);
  }

  void _drawVoltmeter(Canvas canvas, Offset center, String label, String reading) {
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = const Color(0xFF002B45)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawText(canvas, Offset(center.dx - 4, center.dy - 5), 'V', color: Colors.white, fontSize: 9, isBold: true);
    _drawText(canvas, Offset(center.dx - 16, center.dy + 14), '$label: $reading', color: Colors.lightBlueAccent, fontSize: 8);
  }

  void _drawDcSource(Canvas canvas, Offset center, String name, String value) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Battery plates
    canvas.drawLine(Offset(center.dx - 12, center.dy - 6), Offset(center.dx + 12, center.dy - 6), p..strokeWidth = 2.5);
    canvas.drawLine(Offset(center.dx - 6, center.dy + 6), Offset(center.dx + 6, center.dy + 6), p..strokeWidth = 1.5);

    _drawText(canvas, Offset(center.dx - 14, center.dy - 20), '+', color: Colors.redAccent, fontSize: 10, isBold: true);
    _drawText(canvas, Offset(center.dx - 18, center.dy + 12), name, color: Colors.grey, fontSize: 8);
    _drawText(canvas, Offset(center.dx - 14, center.dy + 22), value, color: Colors.cyanAccent, fontSize: 8, isBold: true);
  }

  void _drawGndSymbol(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(Offset(center.dx - 10, center.dy), Offset(center.dx + 10, center.dy), paint);
    canvas.drawLine(Offset(center.dx - 6, center.dy + 4), Offset(center.dx + 6, center.dy + 4), paint);
    canvas.drawLine(Offset(center.dx - 2, center.dy + 8), Offset(center.dx + 2, center.dy + 8), paint);
  }

  void _drawCurrentFlow(Canvas canvas, Size size, double midY, double topY, double bottomY, double vbbX, double bjtCenterX, double vccX) {
    if (ib <= 0.01) return; // Cutoff: no current flow animation

    final ibParticlePaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;

    final icParticlePaint = Paint()
      ..color = const Color(0xFF06D6A0)
      ..style = PaintingStyle.fill;

    // 1. Base Current Flow (Vbb -> Base)
    for (int i = 0; i < 4; i++) {
      final double t = (animProgress + (i / 4.0)) % 1.0;
      final double px = vbbX + t * (bjtCenterX - vbbX);
      canvas.drawCircle(Offset(px, midY), 2.5, ibParticlePaint);
    }

    // 2. Collector Current Flow (Vcc -> Collector)
    for (int i = 0; i < 5; i++) {
      final double t = (animProgress + (i / 5.0)) % 1.0;
      final double px = vccX - t * (vccX - bjtCenterX);
      canvas.drawCircle(Offset(px, topY), 2.8, icParticlePaint);
    }

    // Collector down into transistor
    for (int i = 0; i < 2; i++) {
      final double t = (animProgress + (i / 2.0)) % 1.0;
      final double py = topY + t * (midY - 28 - topY);
      canvas.drawCircle(Offset(bjtCenterX, py), 2.8, icParticlePaint);
    }

    // 3. Emitter Current Flow (IE = IB + IC out to GND)
    for (int i = 0; i < 3; i++) {
      final double t = (animProgress + (i / 3.0)) % 1.0;
      final double py = (midY + 28) + t * (bottomY - (midY + 28));
      canvas.drawCircle(Offset(bjtCenterX, py), 3.0, Paint()..color = Colors.white);
    }
  }

  void _drawText(Canvas canvas, Offset offset, String text, {Color color = Colors.white, double fontSize = 9, bool isBold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ProteusSchematicPainter oldDelegate) => true;
}
