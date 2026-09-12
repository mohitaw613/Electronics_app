import 'package:flutter/material.dart';

/// Accurate CAD Circuit Schematic Widget for BJT Common Emitter (Experiment 5).
/// Features physically accurate interconnections between Base, Collector, and Emitter,
/// dedicated parallel Voltmeters measuring Vbe and Vce with probe wires and junction nodes,
/// series Ammeters for Ib and Ic, and live animated current flow.
class ProteusBjtCircuit extends StatefulWidget {
  final double vbb; // Base supply voltage in Volts
  final double vcc; // Collector supply voltage in Volts
  final double rb;  // Base resistor in kΩ
  final double rc;  // Collector resistor in kΩ
  final double vbe; // Measured Base-Emitter voltage in Volts
  final double vce; // Measured Collector-Emitter voltage in Volts
  final double ib;  // Base current in µA
  final double ic;  // Collector current in mA
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
    return RepaintBoundary(
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF07141E), // Professional dark CAD schematic background
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
        child: Column(
          children: [
            // CAD Header Title Bar (Dedicated space, clean alignment, never cut off)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1E2C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(9),
                  topRight: Radius.circular(9),
                ),
                border: Border(bottom: BorderSide(color: Color(0xFF17425C), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003554),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'CIRCUIT SCHEMATIC',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BJT CE CONFIGURATION (BC547 NPN)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Schematic Canvas with animated current particles
            Expanded(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _SchematicPainter(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SchematicPainter extends CustomPainter {
  final double animProgress;
  final double vbb;
  final double vcc;
  final double rb;
  final double rc;
  final double vbe;
  final double vce;
  final double ib;
  final double ic;

  _SchematicPainter({
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
    _drawCadGrid(canvas, size);

    // Key Coordinates in Schematic
    final double midY = size.height * 0.46;
    final double topY = size.height * 0.16;
    final double bottomY = size.height * 0.86;

    final double vbbX = size.width * 0.07;
    final double rbX = size.width * 0.20;
    final double ammeterBX = size.width * 0.33;
    final double vbeVoltX = size.width * 0.41;

    final double bjtCenterX = size.width * 0.50;
    final double bjtBaseX = bjtCenterX - 10;
    final double bjtLeadX = bjtCenterX + 12; // Collector and Emitter vertical column
    final double bjtCollectorY = midY - 26;
    final double bjtEmitterY = midY + 26;

    final double vceVoltX = size.width * 0.60;
    final double ammeterCX = size.width * 0.69;
    final double rcX = size.width * 0.81;
    final double vccX = size.width * 0.93;

    final wirePaint = Paint()
      ..color = const Color(0xFF00E5FF) // Clean cyan schematic wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final probePaint = Paint()
      ..color = const Color(0xFF48CAE4) // Voltmeter probe wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. INPUT CIRCUIT (Left)
    // ─────────────────────────────────────────────────────────────────────────
    // Vbb supply up to midY
    canvas.drawLine(Offset(vbbX, bottomY), Offset(vbbX, midY), wirePaint);
    // Vbb to Rb left
    canvas.drawLine(Offset(vbbX, midY), Offset(rbX - 16, midY), wirePaint);
    // Rb right to Ammeter Ib
    canvas.drawLine(Offset(rbX + 16, midY), Offset(ammeterBX - 13, midY), wirePaint);
    // Ammeter Ib to Base junction node
    canvas.drawLine(Offset(ammeterBX + 13, midY), Offset(vbeVoltX, midY), wirePaint);
    // Base junction node to Transistor Base terminal
    canvas.drawLine(Offset(vbeVoltX, midY), Offset(bjtBaseX - 12, midY), wirePaint);
    // Transistor external lead into Base bar
    canvas.drawLine(Offset(bjtBaseX - 12, midY), Offset(bjtBaseX, midY), wirePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. OUTPUT CIRCUIT (Right)
    // ─────────────────────────────────────────────────────────────────────────
    // Vcc supply up to topY
    canvas.drawLine(Offset(vccX, bottomY), Offset(vccX, topY), wirePaint);
    // Vcc to Rc right
    canvas.drawLine(Offset(vccX, topY), Offset(rcX + 16, topY), wirePaint);
    // Rc left to Ammeter Ic
    canvas.drawLine(Offset(rcX - 16, topY), Offset(ammeterCX + 13, topY), wirePaint);
    // Ammeter Ic to Collector junction node
    canvas.drawLine(Offset(ammeterCX - 13, topY), Offset(vceVoltX, topY), wirePaint);
    // Collector junction node over to Transistor Collector vertical line
    canvas.drawLine(Offset(vceVoltX, topY), Offset(bjtLeadX, topY), wirePaint);
    // Down to Collector terminal
    canvas.drawLine(Offset(bjtLeadX, topY), Offset(bjtLeadX, bjtCollectorY), wirePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 3. COMMON EMITTER & GROUND RAIL
    // ─────────────────────────────────────────────────────────────────────────
    // Emitter terminal down to Ground rail
    canvas.drawLine(Offset(bjtLeadX, bjtEmitterY), Offset(bjtLeadX, bottomY), wirePaint);

    // Common Ground Rail (connecting Vbb-, Vbe-, Emitter, Vce-, Vcc-)
    canvas.drawLine(Offset(vbbX, bottomY), Offset(vccX, bottomY), wirePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 4. VOLTMETERS IN PARALLEL WITH MEASURING PROBES
    // ─────────────────────────────────────────────────────────────────────────
    final double voltMeterY = midY + 40;

    // (A) VBE Voltmeter in parallel across Base and Emitter
    // Probe 1: from Base wire (at vbeVoltX, midY) down to Voltmeter VBE
    canvas.drawLine(Offset(vbeVoltX, midY), Offset(vbeVoltX, voltMeterY - 12), probePaint);
    // Probe 2: from Voltmeter VBE down to Ground rail
    canvas.drawLine(Offset(vbeVoltX, voltMeterY + 12), Offset(vbeVoltX, bottomY), probePaint);

    // (B) VCE Voltmeter in parallel across Collector and Emitter
    // Probe 1: from Collector wire (at vceVoltX, topY) down to Voltmeter VCE
    canvas.drawLine(Offset(vceVoltX, topY), Offset(vceVoltX, voltMeterY - 12), probePaint);
    // Probe 2: from Voltmeter VCE down to Ground rail
    canvas.drawLine(Offset(vceVoltX, voltMeterY + 12), Offset(vceVoltX, bottomY), probePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 5. SOLDER JUNCTION NODES (Dots indicating physical connections)
    // ─────────────────────────────────────────────────────────────────────────
    _drawJunctionDot(canvas, Offset(vbeVoltX, midY));     // Base probe junction
    _drawJunctionDot(canvas, Offset(vbeVoltX, bottomY));  // Vbe ground return junction
    _drawJunctionDot(canvas, Offset(vceVoltX, topY));     // Collector probe junction
    _drawJunctionDot(canvas, Offset(vceVoltX, bottomY));  // Vce ground return junction
    _drawJunctionDot(canvas, Offset(bjtLeadX, bottomY));  // Emitter ground junction

    // ─────────────────────────────────────────────────────────────────────────
    // 6. DRAW COMPONENTS
    // ─────────────────────────────────────────────────────────────────────────
    // DC Supply V1 (Vbb)
    _drawDcSource(canvas, Offset(vbbX, midY + 18), 'V1 (Vbb)', '${vbb.toStringAsFixed(1)} V');

    // Base Resistor R1 (Rb)
    _drawResistor(canvas, Offset(rbX, midY), 'R1 (Rb)', '${rb.toStringAsFixed(0)} kΩ');

    // Base Ammeter (µA)
    _drawMeter(canvas, Offset(ammeterBX, midY), 'µA', '${ib.toStringAsFixed(1)} µA', Colors.amberAccent);

    // Base-Emitter Voltmeter (VBE)
    _drawVoltmeter(canvas, Offset(vbeVoltX, voltMeterY), 'VBE', '${vbe.toStringAsFixed(3)} V');

    // Transistor Q1 (BC547 NPN)
    _drawBjtTransistor(canvas, Offset(bjtCenterX, midY), bjtBaseX, bjtLeadX, bjtCollectorY, bjtEmitterY);

    // Collector-Emitter Voltmeter (VCE)
    _drawVoltmeter(canvas, Offset(vceVoltX, voltMeterY), 'VCE', '${vce.toStringAsFixed(2)} V');

    // Collector Ammeter (mA)
    _drawMeter(canvas, Offset(ammeterCX, topY), 'mA', '${ic.toStringAsFixed(2)} mA', Colors.greenAccent);

    // Collector Resistor R2 (Rc)
    _drawResistor(canvas, Offset(rcX, topY), 'R2 (Rc)', '${rc.toStringAsFixed(1)} kΩ');

    // DC Supply V2 (Vcc)
    _drawDcSource(canvas, Offset(vccX, midY), 'V2 (Vcc)', '${vcc.toStringAsFixed(1)} V');

    // Earth / Ground Symbol
    _drawGroundSymbol(canvas, Offset(bjtLeadX, bottomY));

    // ─────────────────────────────────────────────────────────────────────────
    // 7. ANIMATED CURRENT FLOW (Physical Particles)
    // ─────────────────────────────────────────────────────────────────────────
    _drawCurrentParticles(canvas, midY, topY, bottomY, vbbX, bjtBaseX, bjtLeadX, vccX);
  }

  void _drawCadGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF0E2738)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawJunctionDot(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 3.5, Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.fill);
    canvas.drawCircle(pos, 1.5, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  void _drawBjtTransistor(
    Canvas canvas,
    Offset center,
    double bx,
    double leadX,
    double colY,
    double emY,
  ) {
    final tPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Transistor Encapsulation Circle
    canvas.drawCircle(
      center,
      23,
      Paint()
        ..color = const Color(0xFF002B45).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      23,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Base Bar (Thick vertical line)
    canvas.drawLine(Offset(bx, center.dy - 14), Offset(bx, center.dy + 14), tPaint..strokeWidth = 3.5);

    // Collector Internal Branch: from Base bar to leadX
    canvas.drawLine(Offset(bx, center.dy - 5), Offset(leadX, colY + 6), tPaint..strokeWidth = 2.2);
    canvas.drawLine(Offset(leadX, colY + 6), Offset(leadX, colY), tPaint);

    // Emitter Internal Branch with Arrow: from Base bar to leadX
    final emBranchStart = Offset(bx, center.dy + 5);
    final emBranchEnd = Offset(leadX, emY - 6);
    canvas.drawLine(emBranchStart, emBranchEnd, tPaint);
    canvas.drawLine(emBranchEnd, Offset(leadX, emY), tPaint);

    // Emitter Arrow (Pointing Outward for NPN)
    final arrowTip = emBranchEnd;
    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowTip.dx - 6, arrowTip.dy - 2)
      ..lineTo(arrowTip.dx - 3, arrowTip.dy - 6)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Labels
    _drawText(canvas, Offset(center.dx - 18, center.dy - 37), 'Q1 (BC547)', color: Colors.cyanAccent, fontSize: 9.5, isBold: true);
    _drawText(canvas, Offset(bx - 10, center.dy - 12), 'B', color: Colors.amberAccent, fontSize: 8.5, isBold: true);
    _drawText(canvas, Offset(leadX + 5, colY + 4), 'C', color: Colors.greenAccent, fontSize: 8.5, isBold: true);
    _drawText(canvas, Offset(leadX + 5, emY - 12), 'E', color: Colors.white, fontSize: 8.5, isBold: true);
  }

  void _drawResistor(Canvas canvas, Offset center, String name, String value) {
    final rPaint = Paint()
      ..color = const Color(0xFFFFB703) // Schematic gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const double w = 26.0;
    const double h = 10.0;
    final rect = Rect.fromCenter(center: center, width: w, height: h);

    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF0B2538)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(rect, rPaint);

    _drawText(canvas, Offset(center.dx - 18, center.dy - 18), name, color: const Color(0xFFFFB703), fontSize: 8.5, isBold: true);
    _drawText(canvas, Offset(center.dx - 14, center.dy + 10), value, color: Colors.white70, fontSize: 8);
  }

  void _drawMeter(Canvas canvas, Offset center, String unit, String reading, Color color) {
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = const Color(0xFF0A2234)
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

    _drawText(canvas, Offset(center.dx - 5, center.dy - 6), 'A', color: Colors.white, fontSize: 9.5, isBold: true);
    _drawText(canvas, Offset(center.dx - 18, center.dy + 15), reading, color: color, fontSize: 8.5, isBold: true);
  }

  void _drawVoltmeter(Canvas canvas, Offset center, String label, String reading) {
    canvas.drawCircle(
      center,
      12.5,
      Paint()
        ..color = const Color(0xFF002B45)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      12.5,
      Paint()
        ..color = const Color(0xFF48CAE4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawText(canvas, Offset(center.dx - 4.5, center.dy - 5.5), 'V', color: Colors.white, fontSize: 9, isBold: true);
    _drawText(canvas, Offset(center.dx - 18, center.dy + 14), '$label: $reading', color: const Color(0xFF90E0EF), fontSize: 8, isBold: true);
  }

  void _drawDcSource(Canvas canvas, Offset center, String name, String value) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Battery plates (+ long, - short)
    canvas.drawLine(Offset(center.dx - 12, center.dy - 6), Offset(center.dx + 12, center.dy - 6), p..strokeWidth = 2.6);
    canvas.drawLine(Offset(center.dx - 6, center.dy + 6), Offset(center.dx + 6, center.dy + 6), p..strokeWidth = 1.5);

    _drawText(canvas, Offset(center.dx - 13, center.dy - 20), '+', color: Colors.redAccent, fontSize: 10, isBold: true);
    _drawText(canvas, Offset(center.dx - 18, center.dy + 12), name, color: Colors.grey.shade400, fontSize: 8);
    _drawText(canvas, Offset(center.dx - 14, center.dy + 22), value, color: Colors.cyanAccent, fontSize: 8.5, isBold: true);
  }

  void _drawGroundSymbol(Canvas canvas, Offset pos) {
    final p = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawLine(Offset(pos.dx - 10, pos.dy + 3), Offset(pos.dx + 10, pos.dy + 3), p);
    canvas.drawLine(Offset(pos.dx - 6, pos.dy + 7), Offset(pos.dx + 6, pos.dy + 7), p);
    canvas.drawLine(Offset(pos.dx - 2, pos.dy + 11), Offset(pos.dx + 2, pos.dy + 11), p);

    _drawText(canvas, Offset(pos.dx + 12, pos.dy + 2), 'GND', color: Colors.grey, fontSize: 7.5);
  }

  void _drawCurrentParticles(
    Canvas canvas,
    double midY,
    double topY,
    double bottomY,
    double vbbX,
    double bjtBaseX,
    double bjtLeadX,
    double vccX,
  ) {
    if (ib <= 0.01) return; // Transistor in cutoff: no current flow

    final ibParticle = Paint()..color = const Color(0xFFFFD166)..style = PaintingStyle.fill;
    final icParticle = Paint()..color = const Color(0xFF06D6A0)..style = PaintingStyle.fill;
    final ieParticle = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // 1. Base Current Flow: Vbb -> Base
    for (int i = 0; i < 4; i++) {
      final double t = (animProgress + (i / 4.0)) % 1.0;
      final double px = vbbX + t * (bjtBaseX - vbbX);
      canvas.drawCircle(Offset(px, midY), 2.4, ibParticle);
    }

    // 2. Collector Current Flow: Vcc -> Collector
    for (int i = 0; i < 5; i++) {
      final double t = (animProgress + (i / 5.0)) % 1.0;
      final double px = vccX - t * (vccX - bjtLeadX);
      canvas.drawCircle(Offset(px, topY), 2.6, icParticle);
    }
    for (int i = 0; i < 2; i++) {
      final double t = (animProgress + (i / 2.0)) % 1.0;
      final double py = topY + t * (midY - 26 - topY);
      canvas.drawCircle(Offset(bjtLeadX, py), 2.6, icParticle);
    }

    // 3. Emitter Current Flow: Emitter -> GND rail
    for (int i = 0; i < 3; i++) {
      final double t = (animProgress + (i / 3.0)) % 1.0;
      final double py = (midY + 26) + t * (bottomY - (midY + 26));
      canvas.drawCircle(Offset(bjtLeadX, py), 2.8, ieParticle);
    }
  }

  void _drawText(
    Canvas canvas,
    Offset offset,
    String text, {
    required Color color,
    double fontSize = 8,
    bool isBold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SchematicPainter old) => true;
}
