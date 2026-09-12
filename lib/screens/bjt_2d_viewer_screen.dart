import 'dart:math' as math;
import 'package:flutter/material.dart';

enum Bjt2dType {
  to92, // Standard plastic BC547 / 2N3904
  to18Metal, // Metal can BC107 / 2N2222
  to220, // Power transistor TIP31 / BD139
  npnJunction, // Internal 2D semiconductor crystal (N-P-N)
  pnpJunction, // Internal 2D semiconductor crystal (P-N-P)
}

enum BjtViewMode {
  frontPackage, // 2D Front Physical Package View
  bottomPinout, // 2D Bottom Pinout / PCB Footprint View
  internalSymbol, // 2D Internal Semiconductor Cross-Section & Schematic Symbol
}

// Retain alias Bjt3dType and Bjt3dViewerScreen for compatibility with existing tests and imports
typedef Bjt3dType = Bjt2dType;

/// 2D Interactive BJT Transistor Packages & Pinouts Visualizer.
/// Displays clean 2D vector technical diagrams of physical packages,
/// bottom PCB footprint views, and internal semiconductor layer structures.
class Bjt3dViewerScreen extends StatefulWidget {
  const Bjt3dViewerScreen({super.key});

  @override
  State<Bjt3dViewerScreen> createState() => _Bjt3dViewerScreenState();
}

class _Bjt3dViewerScreenState extends State<Bjt3dViewerScreen> {
  Bjt2dType _selectedType = Bjt2dType.to92;
  BjtViewMode _viewMode = BjtViewMode.frontPackage;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT Transistor Packages & Pinouts'),
        actions: [
          IconButton(
            tooltip: 'Reset Zoom',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() => _zoom = 1.0),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Transistor Package Selector Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainer : Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2), width: 0.8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip('TO-92 (BC547)', Bjt2dType.to92),
                  const SizedBox(width: 8),
                  _buildTypeChip('TO-18 Metal Can (BC107)', Bjt2dType.to18Metal),
                  const SizedBox(width: 8),
                  _buildTypeChip('TO-220 Power BJT (TIP31)', Bjt2dType.to220),
                  const SizedBox(width: 8),
                  _buildTypeChip('NPN Crystal Junction', Bjt2dType.npnJunction),
                  const SizedBox(width: 8),
                  _buildTypeChip('PNP Crystal Junction', Bjt2dType.pnpJunction),
                ],
              ),
            ),
          ),

          // 2. 2D View Mode Selector (Front Package, Bottom Pinout, Internal / Symbol)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isDark ? cs.surface : Colors.white,
            child: SegmentedButton<BjtViewMode>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: BjtViewMode.frontPackage,
                  icon: Icon(Icons.aspect_ratio, size: 16),
                  label: Text('Front View', style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: BjtViewMode.bottomPinout,
                  icon: Icon(Icons.dialpad, size: 16),
                  label: Text('Bottom Pinout', style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: BjtViewMode.internalSymbol,
                  icon: Icon(Icons.schema, size: 16),
                  label: Text('Symbol & Layers', style: TextStyle(fontSize: 11)),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (set) => setState(() => _viewMode = set.first),
            ),
          ),

          // 3. Interactive 2D Vector Drawing Canvas
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: _Bjt2dDiagramPainter(
                      type: _selectedType,
                      mode: _viewMode,
                      zoom: _zoom,
                      isDark: isDark,
                    ),
                  ),
                ),

                // Zoom Control Buttons (Bottom Right)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in_2d',
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.cyanAccent : Colors.teal.shade800,
                        child: const Icon(Icons.add, size: 20),
                        onPressed: () => setState(() => _zoom = (_zoom + 0.15).clamp(0.6, 2.4)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out_2d',
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.cyanAccent : Colors.teal.shade800,
                        child: const Icon(Icons.remove, size: 20),
                        onPressed: () => setState(() => _zoom = (_zoom - 0.15).clamp(0.6, 2.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Technical Specs & Pinout Guide Panel
          _buildInfoPanel(cs, isDark),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, Bjt2dType type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selectedColor: Colors.teal.shade700,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      checkmarkColor: Colors.white,
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }

  Widget _buildInfoPanel(ColorScheme cs, bool isDark) {
    String title;
    String description;
    String pinout;
    Color badgeColor;

    switch (_selectedType) {
      case Bjt2dType.to92:
        title = 'TO-92 Plastic Package (BC547 NPN Transistor)';
        description = 'Standard small-signal through-hole package with molded matte black epoxy resin. Features flat front face with printed markings, semicircular back, and 3 inline leads.';
        pinout = 'Pin 1: Collector (C) | Pin 2: Base (B) | Pin 3: Emitter (E)  [Facing flat side, leads down]';
        badgeColor = Colors.cyan;
        break;
      case Bjt2dType.to18Metal:
        title = 'TO-18 / TO-39 Hermetic Metal Can (BC107)';
        description = 'Hermetically sealed cylindrical metal package with gold/nickel plating. Features an indexing tab near the Emitter, welded base flange rim, and triangular lead pinout.';
        pinout = 'Pin nearest metal tab: Emitter (E) | Middle: Base (B) | 3rd: Collector (C, case grounded)';
        badgeColor = Colors.amber;
        break;
      case Bjt2dType.to220:
        title = 'TO-220 Power BJT (TIP31 / BD139)';
        description = 'Medium to high-power transistor package with an exposed nickel-plated copper mounting tab with 3.8mm screw hole for heatsink attachment. Features stamped lead shoulders.';
        pinout = 'Pin 1: Base (B) | Pin 2: Collector (C, tab connection) | Pin 3: Emitter (E)';
        badgeColor = Colors.deepOrange;
        break;
      case Bjt2dType.npnJunction:
        title = 'NPN Semiconductor Crystal Structure';
        description = 'Monolithic silicon crystal with heavily doped N+ Emitter, ultra-thin P-type Base (~1µm), and wide N-type Collector with space charge depletion regions and electron injection.';
        pinout = 'Emitter: N+ (Electrons) | Base: P-type (Control layer) | Collector: N-type (Collection)';
        badgeColor = Colors.green;
        break;
      case Bjt2dType.pnpJunction:
        title = 'PNP Semiconductor Crystal Structure';
        description = 'Monolithic silicon crystal with P+ Emitter, thin N-type Base, and wide P Collector. Holes act as majority carriers flowing from Emitter to Collector across depletion layers.';
        pinout = 'Emitter: P+ (Holes) | Base: N-type (Control layer) | Collector: P-type (Collection)';
        badgeColor = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainer : Colors.white,
        border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.2), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(description, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.75), height: 1.3)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
            ),
            child: Text(
              'Pinout: $pinout',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.tealAccent : Colors.teal.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2D Technical Vector Diagram Painter
// ─────────────────────────────────────────────────────────────────────────────

class _Bjt2dDiagramPainter extends CustomPainter {
  final Bjt2dType type;
  final BjtViewMode mode;
  final double zoom;
  final bool isDark;

  const _Bjt2dDiagramPainter({
    required this.type,
    required this.mode,
    required this.zoom,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw background blueprint grid
    _draw2dGrid(canvas, size);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(zoom);

    switch (mode) {
      case BjtViewMode.frontPackage:
        _drawFrontPackage(canvas);
        break;
      case BjtViewMode.bottomPinout:
        _drawBottomPinout(canvas);
        break;
      case BjtViewMode.internalSymbol:
        _drawInternalStructureAndSymbol(canvas);
        break;
    }

    canvas.restore();
  }

  void _draw2dGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    const step = 25.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 1: FRONT PACKAGE PHYSICAL DRAWING (2D)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawFrontPackage(Canvas canvas) {
    switch (type) {
      case Bjt2dType.to92:
        _drawTo92Front(canvas);
        break;
      case Bjt2dType.to18Metal:
        _drawTo18Front(canvas);
        break;
      case Bjt2dType.to220:
        _drawTo220Front(canvas);
        break;
      case Bjt2dType.npnJunction:
      case Bjt2dType.pnpJunction:
        _drawJunctionLayerBlock(canvas, isNpn: type == Bjt2dType.npnJunction);
        break;
    }
  }

  void _drawTo92Front(Canvas canvas) {
    const double bodyW = 100.0;
    const double bodyH = 115.0;
    const double topRadius = 14.0;

    // Body Path with rounded top corners and slight bottom taper
    final bodyPath = Path()
      ..moveTo(-bodyW / 2 + topRadius, -bodyH / 2)
      ..lineTo(bodyW / 2 - topRadius, -bodyH / 2)
      ..quadraticBezierTo(bodyW / 2, -bodyH / 2, bodyW / 2, -bodyH / 2 + topRadius)
      ..lineTo(bodyW / 2 - 4, bodyH / 2)
      ..lineTo(-bodyW / 2 + 4, bodyH / 2)
      ..lineTo(-bodyW / 2, -bodyH / 2 + topRadius)
      ..quadraticBezierTo(-bodyW / 2, -bodyH / 2, -bodyW / 2 + topRadius, -bodyH / 2)
      ..close();

    // Matte black molded plastic gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2D3748), Color(0xFF1A202C), Color(0xFF171923)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-bodyW / 2, -bodyH / 2, bodyW, bodyH));
    canvas.drawPath(bodyPath, bodyPaint);

    // Body border outline
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF4A5568)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Laser printed text
    _drawText(canvas, 'BC547B\nNPN', Offset(0, -10), 13, Colors.white70, isBold: true, center: true);
    _drawText(canvas, 'W 48', Offset(0, 18), 9, Colors.white38, center: true);

    // 3 Metallic leads extending downward with flared shoulders
    _draw2dLead(canvas, -32, bodyH / 2, 85, '1: Collector (C)', Colors.cyanAccent);
    _draw2dLead(canvas, 0, bodyH / 2, 85, '2: Base (B)', Colors.amberAccent);
    _draw2dLead(canvas, 32, bodyH / 2, 85, '3: Emitter (E)', Colors.greenAccent);

    // Title label
    _drawText(canvas, 'TO-92 Package (Front Flat Face)', Offset(0, -bodyH / 2 - 22), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  void _drawTo18Front(Canvas canvas) {
    const double canR = 48.0;
    const double canH = 80.0;
    const double flangeR = 56.0;

    // Metal cylindrical can body
    final bodyRect = Rect.fromCenter(center: const Offset(0, -10), width: canR * 2, height: canH);
    final canPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFD54F), Color(0xFFFFC107), Color(0xFFFFA000), Color(0xFFFFD54F)],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)), canPaint);

    // Welded bottom flange rim
    final flangeRect = Rect.fromLTWH(-flangeR, canH / 2 - 14, flangeR * 2, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(flangeRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFFFB300),
    );

    // Indexing tab on bottom flange
    final tabPath = Path()
      ..moveTo(-flangeR, canH / 2 - 12)
      ..lineTo(-flangeR - 12, canH / 2 - 9)
      ..lineTo(-flangeR, canH / 2 - 6)
      ..close();
    canvas.drawPath(tabPath, Paint()..color = Colors.amberAccent);

    // Stamped label on metal can
    _drawText(canvas, 'BC107\nMetal Can', const Offset(0, -15), 12, const Color(0xFF5D4037), isBold: true, center: true);

    // 3 Leads
    _draw2dLead(canvas, -26, canH / 2 - 4, 80, 'Emitter (Tab)', Colors.greenAccent);
    _draw2dLead(canvas, 0, canH / 2 - 4, 80, 'Base', Colors.amberAccent);
    _draw2dLead(canvas, 26, canH / 2 - 4, 80, 'Collector', Colors.cyanAccent);

    _drawText(canvas, 'TO-18 Hermetic Metal Can', const Offset(0, -canH / 2 - 25), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  void _drawTo220Front(Canvas canvas) {
    const double w = 100.0;
    const double bodyH = 88.0;
    const double tabH = 68.0;

    // 1. Metal mounting tab with hole
    final tabRect = Rect.fromLTWH(-w / 2, -bodyH / 2 - tabH, w, tabH + 8);
    final tabPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(tabRect);
    canvas.drawRRect(RRect.fromRectAndRadius(tabRect, const Radius.circular(6)), tabPaint);

    // Mounting screw hole
    const holeCenter = Offset(0, -bodyH / 2 - tabH / 2);
    canvas.drawCircle(holeCenter, 14, Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));
    canvas.drawCircle(holeCenter, 14, Paint()..color = Colors.blueGrey..style = PaintingStyle.stroke..strokeWidth = 2);

    // 2. Black plastic body
    final bodyRect = Rect.fromLTWH(-w / 2, -bodyH / 2, w, bodyH);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF27272A), Color(0xFF18181B), Color(0xFF09090B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)), bodyPaint);

    // Laser printed text
    _drawText(canvas, 'TIP31C\nPOWER BJT', const Offset(0, -bodyH / 2 + 35), 12, Colors.white70, isBold: true, center: true);

    // 3 Heavy-gauge leads with lead shoulders
    _draw2dLead(canvas, -32, bodyH / 2, 85, '1: Base (B)', Colors.amberAccent, isHeavy: true);
    _draw2dLead(canvas, 0, bodyH / 2, 85, '2: Collector (C)', Colors.cyanAccent, isHeavy: true);
    _draw2dLead(canvas, 32, bodyH / 2, 85, '3: Emitter (E)', Colors.greenAccent, isHeavy: true);

    _drawText(canvas, 'TO-220 Power Package', Offset(0, -bodyH / 2 - tabH - 16), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 2: BOTTOM PINOUT / PCB FOOTPRINT (2D)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawBottomPinout(Canvas canvas) {
    switch (type) {
      case Bjt2dType.to92:
        _drawTo92Bottom(canvas);
        break;
      case Bjt2dType.to18Metal:
        _drawTo18Bottom(canvas);
        break;
      case Bjt2dType.to220:
        _drawTo220Bottom(canvas);
        break;
      case Bjt2dType.npnJunction:
      case Bjt2dType.pnpJunction:
        _drawJunctionLayerBlock(canvas, isNpn: type == Bjt2dType.npnJunction);
        break;
    }
  }

  void _drawTo92Bottom(Canvas canvas) {
    const double radius = 60.0;

    // D-Shape cross-section
    final path = Path()
      ..arcTo(Rect.fromCircle(center: const Offset(0, 0), radius: radius), 0, math.pi, true)
      ..lineTo(radius, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF1E293B));
    canvas.drawPath(path, Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Flat face label
    _drawText(canvas, 'FLAT FACE (Front)', const Offset(0, -16), 10.5, Colors.amberAccent, isBold: true, center: true);

    // 3 Pins in line
    _drawPinDot(canvas, const Offset(-38, 26), '1', 'Collector (C)', Colors.cyanAccent);
    _drawPinDot(canvas, const Offset(0, 26), '2', 'Base (B)', Colors.amberAccent);
    _drawPinDot(canvas, const Offset(38, 26), '3', 'Emitter (E)', Colors.greenAccent);

    _drawText(canvas, 'TO-92 Bottom View (PCB Footprint)', const Offset(0, -radius - 24), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
    _drawText(canvas, 'Standard 1.27mm / 2.54mm Pin Pitch', const Offset(0, radius + 45), 10, isDark ? Colors.white60 : Colors.black54, center: true);
  }

  void _drawTo18Bottom(Canvas canvas) {
    const double radius = 55.0;

    // Metal can bottom circle
    canvas.drawCircle(const Offset(0, 0), radius, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(const Offset(0, 0), radius, Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Index tab on rim
    final tabPath = Path()
      ..moveTo(-radius + 2, -radius * 0.45)
      ..lineTo(-radius - 14, -radius * 0.7)
      ..lineTo(-radius * 0.45, -radius + 2)
      ..close();
    canvas.drawPath(tabPath, Paint()..color = Colors.amberAccent);

    _drawText(canvas, 'Index Tab\n(Emitter Marker)', const Offset(-radius - 32, -radius * 0.7 - 6), 9.5, Colors.amberAccent, isBold: true, center: true);

    // 3 Pins in triangle
    _drawPinDot(canvas, const Offset(-22, -18), 'E', 'Emitter', Colors.greenAccent);
    _drawPinDot(canvas, const Offset(0, 26), 'B', 'Base', Colors.amberAccent);
    _drawPinDot(canvas, const Offset(22, -18), 'C', 'Collector', Colors.cyanAccent);

    _drawText(canvas, 'TO-18 Metal Can Bottom View', const Offset(0, -radius - 32), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  void _drawTo220Bottom(Canvas canvas) {
    const double w = 120.0;
    const double d = 34.0;

    // Rectangular cross-section with heatsink back
    final rect = Rect.fromCenter(center: const Offset(0, 0), width: w, height: d);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(rect, Paint()..color = Colors.blueGrey..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Metal tab back stripe
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -d / 2, w, 6),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    _drawText(canvas, 'Metal Tab (Heatsink Back)', const Offset(0, -d / 2 - 14), 10, Colors.grey, isBold: true, center: true);

    // 3 In-line Pins
    _drawPinDot(canvas, const Offset(-36, 0), '1', 'Base (B)', Colors.amberAccent);
    _drawPinDot(canvas, const Offset(0, 0), '2', 'Collector (C)', Colors.cyanAccent);
    _drawPinDot(canvas, const Offset(36, 0), '3', 'Emitter (E)', Colors.greenAccent);

    _drawText(canvas, 'TO-220 Bottom Pinout (PCB Footprint)', const Offset(0, -d / 2 - 34), 12, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODE 3: INTERNAL SEMICONDUCTOR STRUCTURE & SCHEMATIC SYMBOL (2D)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawInternalStructureAndSymbol(Canvas canvas) {
    final bool isNpn = type != Bjt2dType.pnpJunction;

    // Top half: 2D Semiconductor Crystal Layer Diagram
    canvas.save();
    canvas.translate(0, -40);
    _drawJunctionLayerBlock(canvas, isNpn: isNpn);
    canvas.restore();

    // Bottom half: Standard IEEE Schematic Circuit Symbol
    canvas.save();
    canvas.translate(0, 85);
    _drawSchematicSymbol(canvas, isNpn: isNpn);
    canvas.restore();
  }

  void _drawJunctionLayerBlock(Canvas canvas, {required bool isNpn}) {
    const double totalW = 220.0;
    const double h = 55.0;

    // Layer widths: Emitter = 80, Base = 30 (thin), Collector = 110
    const double eW = 75.0;
    const double bW = 35.0;
    const double cW = 110.0;

    final eColor = isNpn ? const Color(0xFF2563EB) : const Color(0xFF9333EA);
    final bColor = isNpn ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4);
    final cColor = isNpn ? const Color(0xFF059669) : const Color(0xFF7C3AED);

    // Emitter Box
    final eRect = Rect.fromLTWH(-totalW / 2, -h / 2, eW, h);
    canvas.drawRect(eRect, Paint()..color = eColor);
    canvas.drawRect(eRect, Paint()..color = Colors.white24..style = PaintingStyle.stroke);

    // Base Box (Ultra-thin control layer)
    final bRect = Rect.fromLTWH(-totalW / 2 + eW, -h / 2, bW, h);
    canvas.drawRect(bRect, Paint()..color = bColor);
    canvas.drawRect(bRect, Paint()..color = Colors.white24..style = PaintingStyle.stroke);

    // Collector Box
    final cRect = Rect.fromLTWH(-totalW / 2 + eW + bW, -h / 2, cW, h);
    canvas.drawRect(cRect, Paint()..color = cColor);
    canvas.drawRect(cRect, Paint()..color = Colors.white24..style = PaintingStyle.stroke);

    // Layer Text
    _drawText(canvas, isNpn ? 'Emitter\n(N+)' : 'Emitter\n(P+)', Offset(-totalW / 2 + eW / 2, -6), 10.5, Colors.white, isBold: true, center: true);
    _drawText(canvas, isNpn ? 'Base\n(P)' : 'Base\n(N)', Offset(-totalW / 2 + eW + bW / 2, -6), 9.5, Colors.white, isBold: true, center: true);
    _drawText(canvas, isNpn ? 'Collector\n(N)' : 'Collector\n(P)', Offset(-totalW / 2 + eW + bW + cW / 2, -6), 10.5, Colors.white, isBold: true, center: true);

    // Depletion Barrier Dotted Lines
    final dPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-totalW / 2 + eW, -h / 2), Offset(-totalW / 2 + eW, h / 2), dPaint);
    canvas.drawLine(Offset(-totalW / 2 + eW + bW, -h / 2), Offset(-totalW / 2 + eW + bW, h / 2), dPaint);

    _drawText(canvas, isNpn ? 'NPN Crystal Layer Structure' : 'PNP Crystal Layer Structure', Offset(0, -h / 2 - 16), 11.5, isDark ? Colors.white : Colors.black87, isBold: true, center: true);
  }

  void _drawSchematicSymbol(Canvas canvas, {required bool isNpn}) {
    final symPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black87
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Encapsulation circle
    canvas.drawCircle(Offset.zero, 30, symPaint..strokeWidth = 1.4);

    // Base Bar (thick vertical)
    canvas.drawLine(const Offset(-10, -18), const Offset(-10, 18), symPaint..strokeWidth = 3.5);

    // Base Terminal Lead
    canvas.drawLine(const Offset(-35, 0), const Offset(-10, 0), symPaint..strokeWidth = 2.0);
    _drawText(canvas, 'B', const Offset(-45, -6), 11, Colors.amberAccent, isBold: true);

    // Collector Branch
    canvas.drawLine(const Offset(-10, -8), const Offset(14, -22), symPaint);
    canvas.drawLine(const Offset(14, -22), const Offset(14, -38), symPaint);
    _drawText(canvas, 'C', const Offset(20, -38), 11, Colors.cyanAccent, isBold: true);

    // Emitter Branch
    canvas.drawLine(const Offset(-10, 8), const Offset(14, 22), symPaint);
    canvas.drawLine(const Offset(14, 22), const Offset(14, 38), symPaint);
    _drawText(canvas, 'E', const Offset(20, 28), 11, Colors.greenAccent, isBold: true);

    // Emitter Arrow: Points OUTWARD for NPN, INWARD for PNP
    final arrowTip = const Offset(14, 22);
    final arrowPath = Path();
    if (isNpn) {
      arrowPath.moveTo(arrowTip.dx, arrowTip.dy);
      arrowPath.lineTo(arrowTip.dx - 8, arrowTip.dy - 3);
      arrowPath.lineTo(arrowTip.dx - 4, arrowTip.dy - 8);
    } else {
      arrowPath.moveTo(arrowTip.dx - 12, arrowTip.dy - 6);
      arrowPath.lineTo(arrowTip.dx - 4, arrowTip.dy - 3);
      arrowPath.lineTo(arrowTip.dx - 7, arrowTip.dy + 4);
    }
    arrowPath.close();
    canvas.drawPath(arrowPath, Paint()..color = isDark ? Colors.white : Colors.black87..style = PaintingStyle.fill);

    _drawText(canvas, isNpn ? 'Circuit Schematic Symbol (NPN)' : 'Circuit Schematic Symbol (PNP)', const Offset(0, 48), 10.5, isDark ? Colors.white70 : Colors.black87, isBold: true, center: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Drawing Methods
  // ─────────────────────────────────────────────────────────────────────────
  void _draw2dLead(Canvas canvas, double x, double startY, double length, String label, Color color, {bool isHeavy = false}) {
    final leadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = isHeavy ? 5.0 : 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, startY), Offset(x, startY + length), leadPaint);

    final highlightPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, startY), Offset(x, startY + length), highlightPaint);

    // Pin badge
    final badgeY = startY + length + 14;
    _drawText(canvas, label, Offset(x, badgeY), 9.5, color, isBold: true, center: true);
  }

  void _drawPinDot(Canvas canvas, Offset pos, String pinNum, String label, Color color) {
    canvas.drawCircle(pos, 9, Paint()..color = color);
    canvas.drawCircle(pos, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawText(canvas, pinNum, Offset(pos.dx, pos.dy - 5), 10, Colors.black87, isBold: true, center: true);

    _drawText(canvas, label, Offset(pos.dx, pos.dy + 14), 9, color, isBold: true, center: true);
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize, Color color, {bool isBold = false, bool center = false}) {
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
      textAlign: center ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();

    double dx = offset.dx;
    if (center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _Bjt2dDiagramPainter old) {
    return old.type != type || old.mode != mode || old.zoom != zoom || old.isDark != isDark;
  }
}
