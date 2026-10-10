import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircuitFaultState {
  final bool isEmitterGrounded;
  final bool isVbbConnectedToR1;
  final bool isVccConnectedToR2;
  final bool isR1ToAmmeterIb;
  final bool isAmmeterIbToBase;
  final bool isR2ToAmmeterIc;
  final bool isAmmeterIcToCollector;
  final bool isVbePlusToBase;
  final bool isVbeMinusToGnd;
  final bool isVcePlusToCollector;
  final bool isVceMinusToGnd;
  final bool isPowerGrounded;

  const CircuitFaultState({
    this.isEmitterGrounded = true,
    this.isVbbConnectedToR1 = true,
    this.isVccConnectedToR2 = true,
    this.isR1ToAmmeterIb = true,
    this.isAmmeterIbToBase = true,
    this.isR2ToAmmeterIc = true,
    this.isAmmeterIcToCollector = true,
    this.isVbePlusToBase = true,
    this.isVbeMinusToGnd = true,
    this.isVcePlusToCollector = true,
    this.isVceMinusToGnd = true,
    this.isPowerGrounded = true,
  });

  bool get isCircuitComplete =>
      isEmitterGrounded &&
      isVbbConnectedToR1 &&
      isVccConnectedToR2 &&
      isR1ToAmmeterIb &&
      isAmmeterIbToBase &&
      isR2ToAmmeterIc &&
      isAmmeterIcToCollector &&
      isVbePlusToBase &&
      isVbeMinusToGnd &&
      isVcePlusToCollector &&
      isVceMinusToGnd &&
      isPowerGrounded;

  List<String> get faults {
    final list = <String>[];
    if (!isVbbConnectedToR1) list.add('VBB (+) is not wired to R1.');
    if (!isR1ToAmmeterIb) list.add('R1 Out is not wired to µA Ammeter In.');
    if (!isAmmeterIbToBase) list.add('µA Ammeter Out is not wired to Base (B).');
    if (!isVccConnectedToR2) list.add('VCC (+) is not wired to R2.');
    if (!isR2ToAmmeterIc) list.add('R2 In is not wired to mA Ammeter In.');
    if (!isAmmeterIcToCollector) list.add('mA Ammeter Out is not wired to Collector (C).');
    if (!isEmitterGrounded) list.add('Emitter (E) is not wired to GND.');
    if (!isVbePlusToBase) list.add('VBE Voltmeter (+) is not wired to Base junction.');
    if (!isVbeMinusToGnd) list.add('VBE Voltmeter (-) is not wired to GND.');
    if (!isVcePlusToCollector) list.add('VCE Voltmeter (+) is not wired to Collector junction.');
    if (!isVceMinusToGnd) list.add('VCE Voltmeter (-) is not wired to GND.');
    return list;
  }
}

enum BoardPinId {
  vbbPlus,
  r1In,
  r1Out,
  ammeterIbIn,
  ammeterIbOut,
  bjtBase,
  bjtEmitter,
  bjtCollector,
  ammeterIcIn,
  ammeterIcOut,
  r2In,
  r2Out,
  vccPlus,
  voltmeterVbePlus,
  voltmeterVbeMinus,
  voltmeterVcePlus,
  voltmeterVceMinus,
  commonGnd,
}

enum ComponentSpecType {
  bjt,
  r1,
  r2,
  vbb,
  vcc,
  gnd,
  ammeterIb,
  ammeterIc,
  voltmeterVbe,
  voltmeterVce,
}

class HandWire {
  final BoardPinId from;
  final BoardPinId to;
  final Color color;

  const HandWire({
    required this.from,
    required this.to,
    required this.color,
  });

  bool connects(BoardPinId a, BoardPinId b) =>
      (from == a && to == b) || (from == b && to == a);
}

class VirtualBreadboardWidget extends StatefulWidget {
  final ValueChanged<CircuitFaultState>? onCircuitStateChanged;
  final bool initialComplete;

  const VirtualBreadboardWidget({
    super.key,
    this.onCircuitStateChanged,
    this.initialComplete = true,
  });

  @override
  State<VirtualBreadboardWidget> createState() => _VirtualBreadboardWidgetState();
}

Map<ComponentSpecType, Offset> _getDefaultComponentPositions(Size size, {bool isLarge = false}) {
  final centerX = size.width / 2;
  if (isLarge) {
    final double spread = (size.width * 0.35).clamp(85.0, 140.0);
    final double innerSpread = (spread * 0.52).clamp(48.0, 75.0);
    final double midY = size.height * 0.50;
    final r1CenterX = (centerX - spread - 28 + centerX - innerSpread - 38) / 2;
    final r2CenterX = (centerX + spread + 28 + centerX + innerSpread + 38) / 2;

    return {
      ComponentSpecType.vbb: Offset(size.width * 0.12, size.height * 0.15),
      ComponentSpecType.vcc: Offset(size.width * 0.88, size.height * 0.15),
      ComponentSpecType.gnd: Offset(centerX, size.height * 0.88),
      ComponentSpecType.r1: Offset(r1CenterX, midY - 20),
      ComponentSpecType.r2: Offset(r2CenterX, midY - 60),
      ComponentSpecType.bjt: Offset(centerX, midY - 5),
      ComponentSpecType.ammeterIb: Offset((centerX - innerSpread - 12 + centerX - 35) / 2, midY - 20),
      ComponentSpecType.ammeterIc: Offset((centerX + 35 + centerX + innerSpread + 12) / 2, midY - 60),
      ComponentSpecType.voltmeterVbe: Offset(centerX - 70, midY + 112),
      ComponentSpecType.voltmeterVce: Offset(centerX + 70, midY + 112),
    };
  } else {
    return {
      ComponentSpecType.vbb: const Offset(42, 42),
      ComponentSpecType.vcc: Offset(size.width - 42, 42),
      ComponentSpecType.gnd: Offset(centerX, 268),
      ComponentSpecType.r1: Offset(centerX - 96, 110),
      ComponentSpecType.r2: Offset(centerX + 96, 78),
      ComponentSpecType.bjt: Offset(centerX, 120),
      ComponentSpecType.ammeterIb: Offset(centerX - 29, 110),
      ComponentSpecType.ammeterIc: Offset(centerX + 29, 78),
      ComponentSpecType.voltmeterVbe: Offset(centerX - 52, 215),
      ComponentSpecType.voltmeterVce: Offset(centerX + 52, 215),
    };
  }
}

Map<BoardPinId, Offset> _calculatePinPositionsFromComponents(
  Map<ComponentSpecType, Offset> compPositions,
  Size size, {
  bool isLarge = false,
}) {
  final bjt = compPositions[ComponentSpecType.bjt]!;
  final r1 = compPositions[ComponentSpecType.r1]!;
  final r2 = compPositions[ComponentSpecType.r2]!;
  final amIb = compPositions[ComponentSpecType.ammeterIb]!;
  final amIc = compPositions[ComponentSpecType.ammeterIc]!;
  final vmVbe = compPositions[ComponentSpecType.voltmeterVbe]!;
  final vmVce = compPositions[ComponentSpecType.voltmeterVce]!;
  final vbb = compPositions[ComponentSpecType.vbb]!;
  final vcc = compPositions[ComponentSpecType.vcc]!;
  final gnd = compPositions[ComponentSpecType.gnd]!;

  final rOffset = isLarge ? 24.0 : 20.0;
  final amOffset = isLarge ? 18.0 : 15.0;
  final vmOffset = isLarge ? 22.0 : 18.0;

  return {
    BoardPinId.vbbPlus: vbb.translate(isLarge ? 20.0 : 16.0, 0),
    BoardPinId.vccPlus: vcc.translate(isLarge ? -20.0 : -16.0, 0),
    BoardPinId.commonGnd: gnd.translate(0, isLarge ? -20.0 : -16.0),
    BoardPinId.r1In: r1.translate(-rOffset, 0),
    BoardPinId.r1Out: r1.translate(rOffset, 0),
    BoardPinId.r2In: r2.translate(-rOffset, 0),
    BoardPinId.r2Out: r2.translate(rOffset, 0),
    BoardPinId.ammeterIbIn: amIb.translate(-amOffset, 0),
    BoardPinId.ammeterIbOut: amIb.translate(amOffset, 0),
    BoardPinId.ammeterIcIn: amIc.translate(-amOffset, 0),
    BoardPinId.ammeterIcOut: amIc.translate(amOffset, 0),
    BoardPinId.bjtBase: bjt.translate(isLarge ? -24 : -18, isLarge ? 28 : 24),
    BoardPinId.bjtCollector: bjt.translate(0, isLarge ? -35 : -28),
    BoardPinId.bjtEmitter: bjt.translate(isLarge ? 24 : 18, isLarge ? 28 : 24),
    BoardPinId.voltmeterVbePlus: vmVbe.translate(0, -vmOffset),
    BoardPinId.voltmeterVbeMinus: vmVbe.translate(0, vmOffset),
    BoardPinId.voltmeterVcePlus: vmVce.translate(0, -vmOffset),
    BoardPinId.voltmeterVceMinus: vmVce.translate(0, vmOffset),
  };
}

ComponentSpecType? _hitTestComponentFromPositions(
  Offset localPos,
  Map<ComponentSpecType, Offset> compPositions, {
  bool isLarge = false,
}) {
  for (final entry in compPositions.entries) {
    final center = entry.value;
    final double radius;
    switch (entry.key) {
      case ComponentSpecType.bjt:
        radius = isLarge ? 30.0 : 25.0;
        break;
      case ComponentSpecType.r1:
      case ComponentSpecType.r2:
        radius = isLarge ? 28.0 : 24.0;
        break;
      case ComponentSpecType.ammeterIb:
      case ComponentSpecType.ammeterIc:
      case ComponentSpecType.voltmeterVbe:
      case ComponentSpecType.voltmeterVce:
        radius = isLarge ? 26.0 : 22.0;
        break;
      case ComponentSpecType.vbb:
      case ComponentSpecType.vcc:
      case ComponentSpecType.gnd:
        radius = isLarge ? 24.0 : 20.0;
        break;
    }
    if ((localPos - center).distance <= radius) {
      return entry.key;
    }
  }
  return null;
}

class _VirtualBreadboardWidgetState extends State<VirtualBreadboardWidget> {
  final List<HandWire> _wires = [];

  Map<ComponentSpecType, Offset>? _customComponentPositions;
  ComponentSpecType? _draggingComponent;
  Offset _componentDragOffset = Offset.zero;

  BoardPinId? _selectedPin;
  BoardPinId? _draggingFromPin;
  Offset? _currentDragPos;

  Color _selectedWireColor = Colors.red;

  // Power control panel state
  bool _powerOn = false;
  double _voltage = 5.0;
  double _frequency = 50.0;

  static const List<Color> _availableWireColors = [
    Colors.red,
    Colors.black87,
    Colors.amber,
    Colors.green,
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialComplete) {
      _loadStandardWiring();
    } else {
      _notifyState();
    }
  }

  void _loadStandardWiring() {
    _wires.clear();
    _wires.addAll([
      const HandWire(from: BoardPinId.vbbPlus, to: BoardPinId.r1In, color: Colors.amber),
      const HandWire(from: BoardPinId.r1Out, to: BoardPinId.ammeterIbIn, color: Colors.blueAccent),
      const HandWire(from: BoardPinId.ammeterIbOut, to: BoardPinId.bjtBase, color: Colors.blueAccent),
      const HandWire(from: BoardPinId.vccPlus, to: BoardPinId.r2Out, color: Colors.red),
      const HandWire(from: BoardPinId.r2In, to: BoardPinId.ammeterIcIn, color: Colors.black87),
      const HandWire(from: BoardPinId.ammeterIcOut, to: BoardPinId.bjtCollector, color: Colors.black87),
      const HandWire(from: BoardPinId.bjtEmitter, to: BoardPinId.commonGnd, color: Colors.green),
      const HandWire(from: BoardPinId.voltmeterVbePlus, to: BoardPinId.bjtBase, color: Colors.amber),
      const HandWire(from: BoardPinId.voltmeterVbeMinus, to: BoardPinId.commonGnd, color: Colors.green),
      const HandWire(from: BoardPinId.voltmeterVcePlus, to: BoardPinId.bjtCollector, color: Colors.red),
      const HandWire(from: BoardPinId.voltmeterVceMinus, to: BoardPinId.commonGnd, color: Colors.green),
    ]);
    _notifyState();
  }

  CircuitFaultState _calculateState() {
    bool hasWire(BoardPinId a, BoardPinId b) =>
        _wires.any((w) => w.connects(a, b));

    return CircuitFaultState(
      isVbbConnectedToR1: hasWire(BoardPinId.vbbPlus, BoardPinId.r1In),
      isR1ToAmmeterIb: hasWire(BoardPinId.r1Out, BoardPinId.ammeterIbIn),
      isAmmeterIbToBase: hasWire(BoardPinId.ammeterIbOut, BoardPinId.bjtBase),
      isVccConnectedToR2: hasWire(BoardPinId.vccPlus, BoardPinId.r2Out) ||
          hasWire(BoardPinId.vccPlus, BoardPinId.r2In),
      isR2ToAmmeterIc: hasWire(BoardPinId.r2In, BoardPinId.ammeterIcIn),
      isAmmeterIcToCollector: hasWire(BoardPinId.ammeterIcOut, BoardPinId.bjtCollector),
      isEmitterGrounded: hasWire(BoardPinId.bjtEmitter, BoardPinId.commonGnd),
      isVbePlusToBase: hasWire(BoardPinId.voltmeterVbePlus, BoardPinId.bjtBase) ||
          hasWire(BoardPinId.voltmeterVbePlus, BoardPinId.ammeterIbOut),
      isVbeMinusToGnd: hasWire(BoardPinId.voltmeterVbeMinus, BoardPinId.commonGnd),
      isVcePlusToCollector: hasWire(BoardPinId.voltmeterVcePlus, BoardPinId.bjtCollector) ||
          hasWire(BoardPinId.voltmeterVcePlus, BoardPinId.ammeterIcOut),
      isVceMinusToGnd: hasWire(BoardPinId.voltmeterVceMinus, BoardPinId.commonGnd),
      isPowerGrounded: true,
    );
  }

  void _notifyState() {
    final state = _calculateState();
    widget.onCircuitStateChanged?.call(state);
  }

  void _toggleWire(BoardPinId from, BoardPinId to) {
    if (from == to) return;
    setState(() {
      final existingIndex = _wires.indexWhere((w) => w.connects(from, to));
      if (existingIndex >= 0) {
        _wires.removeAt(existingIndex);
      } else {
        _wires.add(HandWire(
          from: from,
          to: to,
          color: _selectedWireColor,
        ));
      }
    });
    _notifyState();
  }

  void _clearAllWires() {
    setState(() {
      _wires.clear();
      _selectedPin = null;
      _draggingFromPin = null;
      _currentDragPos = null;
    });
    _notifyState();
  }

  void _undoLastWire() {
    if (_wires.isNotEmpty) {
      setState(() {
        _wires.removeLast();
      });
      _notifyState();
    }
  }

  Future<void> _openLargeWorkbench() async {
    final updatedWires = await Navigator.push<List<HandWire>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => LargeBreadboardScreen(
          initialWires: List.from(_wires),
          initialWireColor: _selectedWireColor,
        ),
      ),
    );

    if (updatedWires != null) {
      setState(() {
        _wires.clear();
        _wires.addAll(updatedWires);
        _selectedPin = null;
        _draggingFromPin = null;
        _currentDragPos = null;
      });
      _notifyState();
    }
  }

  Map<ComponentSpecType, Offset> _getComponentPositions(Size size) {
    if (_customComponentPositions != null) {
      return _customComponentPositions!;
    }
    return _getDefaultComponentPositions(size);
  }

  Map<BoardPinId, Offset> _calculatePinPositions(Size size) {
    return _calculatePinPositionsFromComponents(_getComponentPositions(size), size);
  }

  BoardPinId? _hitTestPin(Offset localPos, Size size, {double radius = 13.0}) {
    final pinMap = _calculatePinPositions(size);
    BoardPinId? closest;
    double minDistance = radius;
    pinMap.forEach((id, pos) {
      final d = (pos - localPos).distance;
      if (d < minDistance) {
        minDistance = d;
        closest = id;
      }
    });
    return closest;
  }

  ComponentSpecType? _hitTestComponent(Offset localPos, Size size) {
    return _hitTestComponentFromPositions(localPos, _getComponentPositions(size));
  }

  String _pinName(BoardPinId pin) {
    switch (pin) {
      case BoardPinId.vbbPlus:
        return 'VBB (+) Supply Post';
      case BoardPinId.r1In:
        return 'R1 In Lead';
      case BoardPinId.r1Out:
        return 'R1 Out Lead';
      case BoardPinId.ammeterIbIn:
        return 'µA Ammeter (Ib) In';
      case BoardPinId.ammeterIbOut:
        return 'µA Ammeter (Ib) Out';
      case BoardPinId.bjtBase:
        return 'Base (B) Lead';
      case BoardPinId.bjtCollector:
        return 'Collector (C) Lead';
      case BoardPinId.bjtEmitter:
        return 'Emitter (E) Lead';
      case BoardPinId.ammeterIcIn:
        return 'mA Ammeter (Ic) In';
      case BoardPinId.ammeterIcOut:
        return 'mA Ammeter (Ic) Out';
      case BoardPinId.r2In:
        return 'R2 In Lead';
      case BoardPinId.r2Out:
        return 'R2 Out Lead';
      case BoardPinId.vccPlus:
        return 'VCC (+) Supply Post';
      case BoardPinId.voltmeterVbePlus:
        return 'VBE Voltmeter (+)';
      case BoardPinId.voltmeterVbeMinus:
        return 'VBE Voltmeter (-)';
      case BoardPinId.voltmeterVcePlus:
        return 'VCE Voltmeter (+)';
      case BoardPinId.voltmeterVceMinus:
        return 'VCE Voltmeter (-)';
      case BoardPinId.commonGnd:
        return 'Common GND Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = _calculateState();
    final isComplete = state.isCircuitComplete;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header with Fullscreen Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (isComplete ? Colors.green : Colors.amber).withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isComplete ? Colors.green : Colors.amber.shade700,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.handshake,
                    color: isComplete ? Colors.green : Colors.amber.shade800,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isComplete
                          ? 'Circuit Complete: All Wires Connected by Hand ✓'
                          : 'Manual Wiring: ${_wires.length}/11 Connections (${11 - math.min(11, _wires.length)} pending)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isComplete ? Colors.green.shade800 : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 22),
                    tooltip: 'Large Wiring Screen',
                    visualDensity: VisualDensity.compact,
                    onPressed: _openLargeWorkbench,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Large Workbench Open Pill Button
            InkWell(
              onTap: _openLargeWorkbench,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.blueGrey.shade800, Colors.blueGrey.shade900]
                        : [Colors.blue.shade50, Colors.indigo.shade50],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_full, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Open Larger Screen for Hand Wiring ⛶',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Instructional Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedPin != null
                          ? '👉 Selected: ${_pinName(_selectedPin!)}. Touch or drag to target pin!'
                          : '🖐️ Touch or drag pins to connect wires',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_selectedPin != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedPin = null),
                      child: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Wire in Hand Color Palette
            Row(
              children: [
                const Text(
                  'Wire in Hand:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                for (final c in _availableWireColors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedWireColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedWireColor == c ? cs.primary : Colors.white,
                          width: _selectedWireColor == c ? 2.5 : 1.2,
                        ),
                        boxShadow: [
                          if (_selectedWireColor == c)
                            BoxShadow(
                              color: c.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: _selectedWireColor == c
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${_wires.length} wire${_wires.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Zoomed-Out Realistic Breadboard Canvas
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, 300);
                return Container(
                  height: size.height,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final tappedPin = _hitTestPin(details.localPosition, size);
                      if (tappedPin != null) {
                        if (_selectedPin == null) {
                          setState(() => _selectedPin = tappedPin);
                        } else if (_selectedPin == tappedPin) {
                          setState(() => _selectedPin = null);
                        } else {
                          _toggleWire(_selectedPin!, tappedPin);
                          setState(() => _selectedPin = null);
                        }
                        return;
                      }

                      if (_selectedPin != null) {
                        final tappedComp = _hitTestComponent(details.localPosition, size);
                        if (tappedComp != null) {
                          BoardPinId? targetPin;
                          if (tappedComp == ComponentSpecType.vbb) targetPin = BoardPinId.vbbPlus;
                          if (tappedComp == ComponentSpecType.vcc) targetPin = BoardPinId.vccPlus;
                          if (tappedComp == ComponentSpecType.gnd) targetPin = BoardPinId.commonGnd;
                          if (targetPin != null) {
                            _toggleWire(_selectedPin!, targetPin);
                            setState(() => _selectedPin = null);
                            return;
                          }
                        }
                        setState(() => _selectedPin = null);
                      }
                    },
                    onTapUp: (_) {},
                    onPanStart: (details) {
                      final comp = _hitTestComponent(details.localPosition, size);
                      final pin = _hitTestPin(details.localPosition, size);

                      if (comp != null && pin != null) {
                        final compPos = _getComponentPositions(size)[comp]!;
                        final pinPos = _calculatePinPositions(size)[pin]!;
                        final distToComp = (details.localPosition - compPos).distance;
                        final distToPin = (details.localPosition - pinPos).distance;

                        if (distToComp <= distToPin) {
                          setState(() {
                            _draggingComponent = comp;
                            _componentDragOffset = details.localPosition - compPos;
                          });
                        } else {
                          setState(() {
                            _draggingFromPin = pin;
                            _currentDragPos = details.localPosition;
                          });
                        }
                        return;
                      }

                      if (comp != null) {
                        final compPos = _getComponentPositions(size)[comp]!;
                        setState(() {
                          _draggingComponent = comp;
                          _componentDragOffset = details.localPosition - compPos;
                        });
                        return;
                      }

                      if (pin != null) {
                        setState(() {
                          _draggingFromPin = pin;
                          _currentDragPos = details.localPosition;
                        });
                        return;
                      }
                    },
                    onPanUpdate: (details) {
                      if (_draggingFromPin != null) {
                        setState(() {
                          _currentDragPos = details.localPosition;
                        });
                      } else if (_draggingComponent != null) {
                        final newPos = details.localPosition - _componentDragOffset;
                        final clampedPos = Offset(
                          newPos.dx.clamp(32.0, size.width - 32.0),
                          newPos.dy.clamp(32.0, size.height - 32.0),
                        );
                        setState(() {
                          _customComponentPositions ??= Map.from(_getDefaultComponentPositions(size));
                          _customComponentPositions![_draggingComponent!] = clampedPos;
                        });
                      }
                    },
                    onPanEnd: (details) {
                      if (_draggingFromPin != null && _currentDragPos != null) {
                        final targetPin = _hitTestPin(_currentDragPos!, size);
                        if (targetPin != null && targetPin != _draggingFromPin) {
                          _toggleWire(_draggingFromPin!, targetPin);
                        }
                      }
                      setState(() {
                        _draggingFromPin = null;
                        _currentDragPos = null;
                        _draggingComponent = null;
                      });
                    },
                    onPanCancel: () {
                      setState(() {
                        _draggingFromPin = null;
                        _currentDragPos = null;
                        _draggingComponent = null;
                      });
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _RealisticZoomedBreadboardPainter(
                        wires: _wires,
                        selectedPin: _selectedPin,
                        draggingFromPin: _draggingFromPin,
                        currentDragPos: _currentDragPos,
                        dragWireColor: _selectedWireColor,
                        isDark: isDark,
                        customComponentPositions: _getComponentPositions(size),
                        draggingComponent: _draggingComponent,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Component Specification Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Specs:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _specChip('BC547 (Q1)', Colors.blue, () => showComponentSpecsSheet(context, ComponentSpecType.bjt)),
                  const SizedBox(width: 5),
                  _specChip('R1 (Base)', Colors.orange, () => showComponentSpecsSheet(context, ComponentSpecType.r1)),
                  const SizedBox(width: 5),
                  _specChip('R2 (Collector)', Colors.purple, () => showComponentSpecsSheet(context, ComponentSpecType.r2)),
                  const SizedBox(width: 5),
                  _specChip('VBB Supply', Colors.amber.shade800, () => showComponentSpecsSheet(context, ComponentSpecType.vbb)),
                  const SizedBox(width: 5),
                  _specChip('VCC Supply', Colors.red, () => showComponentSpecsSheet(context, ComponentSpecType.vcc)),
                  const SizedBox(width: 5),
                  _specChip('GND Rail', Colors.green, () => showComponentSpecsSheet(context, ComponentSpecType.gnd)),
                  const SizedBox(width: 5),
                  _specChip('µA (Ib)', Colors.amberAccent.shade700, () => showComponentSpecsSheet(context, ComponentSpecType.ammeterIb)),
                  const SizedBox(width: 5),
                  _specChip('mA (Ic)', Colors.greenAccent.shade700, () => showComponentSpecsSheet(context, ComponentSpecType.ammeterIc)),
                  const SizedBox(width: 5),
                  _specChip('VBE Meter', Colors.cyan, () => showComponentSpecsSheet(context, ComponentSpecType.voltmeterVbe)),
                  const SizedBox(width: 5),
                  _specChip('VCE Meter', Colors.teal, () => showComponentSpecsSheet(context, ComponentSpecType.voltmeterVce)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Quick Action Buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.undo, size: 14),
                  label: const Text('Undo Wire', style: TextStyle(fontSize: 11)),
                  onPressed: _wires.isNotEmpty ? _undoLastWire : null,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_sweep, size: 14),
                  label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                  onPressed: _wires.isNotEmpty ? _clearAllWires : null,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.restart_alt, size: 14),
                  label: const Text('Reset Layout', style: TextStyle(fontSize: 11)),
                  onPressed: _customComponentPositions != null
                      ? () => setState(() => _customComponentPositions = null)
                      : null,
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.auto_fix_high, size: 14),
                  label: const Text('Auto-Wire', style: TextStyle(fontSize: 11)),
                  onPressed: _loadStandardWiring,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated Large Screen for hands-on, finger-friendly circuit wiring
class LargeBreadboardScreen extends StatefulWidget {
  final List<HandWire> initialWires;
  final Color initialWireColor;

  const LargeBreadboardScreen({
    super.key,
    required this.initialWires,
    required this.initialWireColor,
  });

  @override
  State<LargeBreadboardScreen> createState() => _LargeBreadboardScreenState();
}

class _LargeBreadboardScreenState extends State<LargeBreadboardScreen> {
  late List<HandWire> _wires;
  late Color _selectedWireColor;

  BoardPinId? _selectedPin;
  BoardPinId? _draggingFromPin;
  Offset? _currentDragPos;

  static const List<Color> _availableWireColors = [
    Colors.red,
    Colors.black87,
    Colors.amber,
    Colors.green,
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    _wires = List.from(widget.initialWires);
    _selectedWireColor = widget.initialWireColor;
  }

  void _loadStandardWiring() {
    setState(() {
      _wires.clear();
      _wires.addAll([
        const HandWire(from: BoardPinId.vbbPlus, to: BoardPinId.r1In, color: Colors.amber),
        const HandWire(from: BoardPinId.r1Out, to: BoardPinId.ammeterIbIn, color: Colors.blueAccent),
        const HandWire(from: BoardPinId.ammeterIbOut, to: BoardPinId.bjtBase, color: Colors.blueAccent),
        const HandWire(from: BoardPinId.vccPlus, to: BoardPinId.r2Out, color: Colors.red),
        const HandWire(from: BoardPinId.r2In, to: BoardPinId.ammeterIcIn, color: Colors.black87),
        const HandWire(from: BoardPinId.ammeterIcOut, to: BoardPinId.bjtCollector, color: Colors.black87),
        const HandWire(from: BoardPinId.bjtEmitter, to: BoardPinId.commonGnd, color: Colors.green),
        const HandWire(from: BoardPinId.voltmeterVbePlus, to: BoardPinId.bjtBase, color: Colors.amber),
        const HandWire(from: BoardPinId.voltmeterVbeMinus, to: BoardPinId.commonGnd, color: Colors.green),
        const HandWire(from: BoardPinId.voltmeterVcePlus, to: BoardPinId.bjtCollector, color: Colors.red),
        const HandWire(from: BoardPinId.voltmeterVceMinus, to: BoardPinId.commonGnd, color: Colors.green),
      ]);
    });
  }

  void _toggleWire(BoardPinId from, BoardPinId to) {
    if (from == to) return;
    setState(() {
      final existingIndex = _wires.indexWhere((w) => w.connects(from, to));
      if (existingIndex >= 0) {
        _wires.removeAt(existingIndex);
      } else {
        _wires.add(HandWire(
          from: from,
          to: to,
          color: _selectedWireColor,
        ));
      }
    });
  }

  void _undoLastWire() {
    if (_wires.isNotEmpty) {
      setState(() {
        _wires.removeLast();
      });
    }
  }

  void _clearAllWires() {
    setState(() {
      _wires.clear();
      _selectedPin = null;
      _draggingFromPin = null;
      _currentDragPos = null;
    });
  }

  Map<ComponentSpecType, Offset>? _customComponentPositions;
  ComponentSpecType? _draggingComponent;
  Offset _componentDragOffset = Offset.zero;

  Map<ComponentSpecType, Offset> _getLargeComponentPositions(Size size) {
    if (_customComponentPositions != null) {
      return _customComponentPositions!;
    }
    return _getDefaultComponentPositions(size, isLarge: true);
  }

  Map<BoardPinId, Offset> _calculateLargePinPositions(Size size) {
    return _calculatePinPositionsFromComponents(_getLargeComponentPositions(size), size, isLarge: true);
  }

  BoardPinId? _hitTestLargePin(Offset localPos, Size size, {double radius = 16.0}) {
    final pinMap = _calculateLargePinPositions(size);
    BoardPinId? closest;
    double minDistance = radius;
    pinMap.forEach((id, pos) {
      final d = (pos - localPos).distance;
      if (d < minDistance) {
        minDistance = d;
        closest = id;
      }
    });
    return closest;
  }

  ComponentSpecType? _hitTestLargeComponent(Offset localPos, Size size) {
    return _hitTestComponentFromPositions(localPos, _getLargeComponentPositions(size), isLarge: true);
  }

  String _pinName(BoardPinId pin) {
    switch (pin) {
      case BoardPinId.vbbPlus:
        return 'VBB (+) Supply Post';
      case BoardPinId.r1In:
        return 'R1 In Lead';
      case BoardPinId.r1Out:
        return 'R1 Out Lead';
      case BoardPinId.ammeterIbIn:
        return 'µA Ammeter (Ib) In';
      case BoardPinId.ammeterIbOut:
        return 'µA Ammeter (Ib) Out';
      case BoardPinId.bjtBase:
        return 'Base (B) Lead';
      case BoardPinId.bjtCollector:
        return 'Collector (C) Lead';
      case BoardPinId.bjtEmitter:
        return 'Emitter (E) Lead';
      case BoardPinId.ammeterIcIn:
        return 'mA Ammeter (Ic) In';
      case BoardPinId.ammeterIcOut:
        return 'mA Ammeter (Ic) Out';
      case BoardPinId.r2In:
        return 'R2 In Lead';
      case BoardPinId.r2Out:
        return 'R2 Out Lead';
      case BoardPinId.vccPlus:
        return 'VCC (+) Supply Post';
      case BoardPinId.voltmeterVbePlus:
        return 'VBE Voltmeter (+)';
      case BoardPinId.voltmeterVbeMinus:
        return 'VBE Voltmeter (-)';
      case BoardPinId.voltmeterVcePlus:
        return 'VCE Voltmeter (+)';
      case BoardPinId.voltmeterVceMinus:
        return 'VCE Voltmeter (-)';
      case BoardPinId.commonGnd:
        return 'Common GND Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool hasWire(BoardPinId a, BoardPinId b) => _wires.any((w) => w.connects(a, b));
    final isVbbToR1 = hasWire(BoardPinId.vbbPlus, BoardPinId.r1In);
    final isR1ToIb = hasWire(BoardPinId.r1Out, BoardPinId.ammeterIbIn);
    final isIbToBase = hasWire(BoardPinId.ammeterIbOut, BoardPinId.bjtBase);
    final isVccToR2 = hasWire(BoardPinId.vccPlus, BoardPinId.r2Out) || hasWire(BoardPinId.vccPlus, BoardPinId.r2In);
    final isR2ToIc = hasWire(BoardPinId.r2In, BoardPinId.ammeterIcIn);
    final isIcToColl = hasWire(BoardPinId.ammeterIcOut, BoardPinId.bjtCollector);
    final isEmitterGnd = hasWire(BoardPinId.bjtEmitter, BoardPinId.commonGnd);
    final isVbePlusToBase = hasWire(BoardPinId.voltmeterVbePlus, BoardPinId.bjtBase) || hasWire(BoardPinId.voltmeterVbePlus, BoardPinId.ammeterIbOut);
    final isVbeMinusToGnd = hasWire(BoardPinId.voltmeterVbeMinus, BoardPinId.commonGnd);
    final isVcePlusToColl = hasWire(BoardPinId.voltmeterVcePlus, BoardPinId.bjtCollector) || hasWire(BoardPinId.voltmeterVcePlus, BoardPinId.ammeterIcOut);
    final isVceMinusToGnd = hasWire(BoardPinId.voltmeterVceMinus, BoardPinId.commonGnd);

    final completedCount = (isVbbToR1 ? 1 : 0) +
        (isR1ToIb ? 1 : 0) +
        (isIbToBase ? 1 : 0) +
        (isVccToR2 ? 1 : 0) +
        (isR2ToIc ? 1 : 0) +
        (isIcToColl ? 1 : 0) +
        (isEmitterGnd ? 1 : 0) +
        (isVbePlusToBase ? 1 : 0) +
        (isVbeMinusToGnd ? 1 : 0) +
        (isVcePlusToColl ? 1 : 0) +
        (isVceMinusToGnd ? 1 : 0);
    final isComplete = completedCount == 11;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hands-On Wiring Workbench', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _wires),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo Wire',
              onPressed: _wires.isNotEmpty ? _undoLastWire : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All Wires',
              onPressed: _wires.isNotEmpty ? _clearAllWires : null,
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset Equipment Layout',
              onPressed: _customComponentPositions != null
                  ? () => setState(() => _customComponentPositions = null)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Auto-Wire Preset',
              onPressed: _loadStandardWiring,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context, _wires),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header progress banner
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isComplete ? Colors.green : Colors.amber).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isComplete ? Colors.green : Colors.amber.shade700, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.handshake,
                      color: isComplete ? Colors.green : Colors.amber.shade800,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isComplete
                                ? 'Circuit Complete: All 11 Connections Wired by Hand ✓'
                                : 'Wiring in Progress: $completedCount/11 Connections (${11 - completedCount} pending)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: isComplete ? Colors.green.shade800 : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                            ),
                          ),
                          Text(
                            _selectedPin != null
                                ? '👉 Touch or drag to target pin from ${_pinName(_selectedPin!)}'
                                : '🖐️ Touch or drag pins to connect wires',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checklist chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _circuitStepPill('1. VBB ➔ R1', isVbbToR1),
                    const SizedBox(width: 6),
                    _circuitStepPill('2. R1 ➔ µA In', isR1ToIb),
                    const SizedBox(width: 6),
                    _circuitStepPill('3. µA Out ➔ Base', isIbToBase),
                    const SizedBox(width: 6),
                    _circuitStepPill('4. VCC ➔ R2', isVccToR2),
                    const SizedBox(width: 6),
                    _circuitStepPill('5. R2 ➔ mA In', isR2ToIc),
                    const SizedBox(width: 6),
                    _circuitStepPill('6. mA Out ➔ Collector', isIcToColl),
                    const SizedBox(width: 6),
                    _circuitStepPill('7. Emitter ➔ GND', isEmitterGnd),
                    const SizedBox(width: 6),
                    _circuitStepPill('8. VBE(+) ➔ Base', isVbePlusToBase),
                    const SizedBox(width: 6),
                    _circuitStepPill('9. VBE(-) ➔ GND', isVbeMinusToGnd),
                    const SizedBox(width: 6),
                    _circuitStepPill('10. VCE(+) ➔ Collector', isVcePlusToColl),
                    const SizedBox(width: 6),
                    _circuitStepPill('11. VCE(-) ➔ GND', isVceMinusToGnd),
                  ],
                ),
              ),

              // Wire Color Selector (Larger Touch Targets)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    const Text('Wire in Hand:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    for (final c in _availableWireColors)
                      GestureDetector(
                        onTap: () => setState(() => _selectedWireColor = c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedWireColor == c ? cs.primary : Colors.white,
                              width: _selectedWireColor == c ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              if (_selectedWireColor == c)
                                BoxShadow(
                                  color: c.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: _selectedWireColor == c
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    const SizedBox(width: 14),
                    Text('${_wires.length} wired', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

              // Expanded Large Breadboard Canvas
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Container(
                        width: size.width,
                        height: size.height,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B1120) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5)),
                          ],
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            final tappedPin = _hitTestLargePin(details.localPosition, size);
                            if (tappedPin != null) {
                              if (_selectedPin == null) {
                                setState(() => _selectedPin = tappedPin);
                              } else if (_selectedPin == tappedPin) {
                                setState(() => _selectedPin = null);
                              } else {
                                _toggleWire(_selectedPin!, tappedPin);
                                setState(() => _selectedPin = null);
                              }
                              return;
                            }

                            if (_selectedPin != null) {
                              final tappedComp = _hitTestLargeComponent(details.localPosition, size);
                              if (tappedComp != null) {
                                BoardPinId? targetPin;
                                if (tappedComp == ComponentSpecType.vbb) targetPin = BoardPinId.vbbPlus;
                                if (tappedComp == ComponentSpecType.vcc) targetPin = BoardPinId.vccPlus;
                                if (tappedComp == ComponentSpecType.gnd) targetPin = BoardPinId.commonGnd;
                                if (targetPin != null) {
                                  _toggleWire(_selectedPin!, targetPin);
                                  setState(() => _selectedPin = null);
                                  return;
                                }
                              }
                              setState(() => _selectedPin = null);
                            }
                          },
                          onTapUp: (_) {},
                          onPanStart: (details) {
                            final comp = _hitTestLargeComponent(details.localPosition, size);
                            final pin = _hitTestLargePin(details.localPosition, size);

                            if (comp != null && pin != null) {
                              final compPos = _getLargeComponentPositions(size)[comp]!;
                              final pinPos = _calculateLargePinPositions(size)[pin]!;
                              final distToComp = (details.localPosition - compPos).distance;
                              final distToPin = (details.localPosition - pinPos).distance;

                              if (distToComp <= distToPin) {
                                setState(() {
                                  _draggingComponent = comp;
                                  _componentDragOffset = details.localPosition - compPos;
                                });
                              } else {
                                setState(() {
                                  _draggingFromPin = pin;
                                  _currentDragPos = details.localPosition;
                                });
                              }
                              return;
                            }

                            if (comp != null) {
                              final compPos = _getLargeComponentPositions(size)[comp]!;
                              setState(() {
                                _draggingComponent = comp;
                                _componentDragOffset = details.localPosition - compPos;
                              });
                              return;
                            }

                            if (pin != null) {
                              setState(() {
                                _draggingFromPin = pin;
                                _currentDragPos = details.localPosition;
                              });
                              return;
                            }
                          },
                          onPanUpdate: (details) {
                            if (_draggingFromPin != null) {
                              setState(() {
                                _currentDragPos = details.localPosition;
                              });
                            } else if (_draggingComponent != null) {
                              final newPos = details.localPosition - _componentDragOffset;
                              final clampedPos = Offset(
                                newPos.dx.clamp(35.0, size.width - 35.0),
                                newPos.dy.clamp(35.0, size.height - 35.0),
                              );
                              setState(() {
                                _customComponentPositions ??= Map.from(_getDefaultComponentPositions(size, isLarge: true));
                                _customComponentPositions![_draggingComponent!] = clampedPos;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            if (_draggingFromPin != null && _currentDragPos != null) {
                              final targetPin = _hitTestLargePin(_currentDragPos!, size);
                              if (targetPin != null && targetPin != _draggingFromPin) {
                                _toggleWire(_draggingFromPin!, targetPin);
                              }
                            }
                            setState(() {
                              _draggingFromPin = null;
                              _currentDragPos = null;
                              _draggingComponent = null;
                            });
                          },
                          onPanCancel: () {
                            setState(() {
                              _draggingFromPin = null;
                              _currentDragPos = null;
                              _draggingComponent = null;
                            });
                          },
                          child: CustomPaint(
                            size: size,
                            painter: _RealisticZoomedBreadboardPainter(
                              wires: _wires,
                              selectedPin: _selectedPin,
                              draggingFromPin: _draggingFromPin,
                              currentDragPos: _currentDragPos,
                              dragWireColor: _selectedWireColor,
                              isDark: isDark,
                              isLarge: true,
                              customComponentPositions: _getLargeComponentPositions(size),
                              draggingComponent: _draggingComponent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Component Specification Chips
              Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Specs:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      _specChip('BC547 (Q1)', Colors.blue, () => showComponentSpecsSheet(context, ComponentSpecType.bjt)),
                      const SizedBox(width: 5),
                      _specChip('R1 (Base)', Colors.orange, () => showComponentSpecsSheet(context, ComponentSpecType.r1)),
                      const SizedBox(width: 5),
                      _specChip('R2 (Collector)', Colors.purple, () => showComponentSpecsSheet(context, ComponentSpecType.r2)),
                      const SizedBox(width: 5),
                      _specChip('VBB Supply', Colors.amber.shade800, () => showComponentSpecsSheet(context, ComponentSpecType.vbb)),
                      const SizedBox(width: 5),
                      _specChip('VCC Supply', Colors.red, () => showComponentSpecsSheet(context, ComponentSpecType.vcc)),
                      const SizedBox(width: 5),
                      _specChip('GND Rail', Colors.green, () => showComponentSpecsSheet(context, ComponentSpecType.gnd)),
                      const SizedBox(width: 5),
                      _specChip('µA (Ib)', Colors.amberAccent.shade700, () => showComponentSpecsSheet(context, ComponentSpecType.ammeterIb)),
                      const SizedBox(width: 5),
                      _specChip('mA (Ic)', Colors.greenAccent.shade700, () => showComponentSpecsSheet(context, ComponentSpecType.ammeterIc)),
                      const SizedBox(width: 5),
                      _specChip('VBE Meter', Colors.cyan, () => showComponentSpecsSheet(context, ComponentSpecType.voltmeterVbe)),
                      const SizedBox(width: 5),
                      _specChip('VCE Meter', Colors.teal, () => showComponentSpecsSheet(context, ComponentSpecType.voltmeterVce)),
                    ],
                  ),
                ),
              ),

              // Bottom Control Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Undo'),
                      onPressed: _wires.isNotEmpty ? _undoLastWire : null,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Clear All'),
                      onPressed: _wires.isNotEmpty ? _clearAllWires : null,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Done & Return to Lab'),
                      onPressed: () => Navigator.pop(context, _wires),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circuitStepPill(String title, bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? Colors.green : Colors.grey.shade400, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.check_circle : Icons.circle_outlined, size: 13, color: isConnected ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
              color: isConnected ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global helper to show component technical specifications modal sheet
void showComponentSpecsSheet(BuildContext context, ComponentSpecType type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  String title;
  String subtitle;
  IconData icon;
  Color themeColor;
  Map<String, String> specs;
  String functionDescription;

  switch (type) {
    case ComponentSpecType.bjt:
      title = 'BC547B NPN Transistor (Q1)';
      subtitle = 'General Purpose Bipolar Junction Transistor';
      icon = Icons.developer_board;
      themeColor = Colors.blueAccent;
      specs = {
        'Type': 'NPN Silicon Epitaxial Planar',
        'Package': 'TO-92 (Through-Hole)',
        'Configuration': 'Common Emitter (CE)',
        'DC Current Gain (h_FE / β)': '110 – 800 (Nominal: 150 – 200)',
        'Forward Drop (V_BE)': '0.65 V – 0.70 V (Silicon)',
        'Collector Current (I_C max)': '100 mA Continuous (200 mA Peak)',
        'Collector-Emitter Voltage (V_CEO max)': '45 V',
        'Collector-Base Voltage (V_CBO max)': '50 V',
        'Power Dissipation (P_tot max)': '500 mW',
        'Lead Pinout': '1: Collector (C) • 2: Base (B) • 3: Emitter (E)',
      };
      functionDescription =
          'Core active amplifying component. In Common Emitter mode, small input base current variations (I_B) control large output collector currents (I_C = β · I_B) to achieve current and voltage amplification.';
      break;

    case ComponentSpecType.r1:
      title = 'Base Resistor R1 (R_B)';
      subtitle = 'Carbon Film Fixed Resistor';
      icon = Icons.linear_scale;
      themeColor = const Color(0xFFD97706);
      specs = {
        'Nominal Resistance': '1,000 Ω (1 kΩ)',
        'Tolerance': '±5% (Gold tolerance band)',
        'Color Bands': 'Brown (1) • Black (0) • Red (×100) • Gold (±5%)',
        'Power Rating': '0.25 W (1/4 Watt)',
        'Maximum Working Voltage': '250 V',
        'Construction': 'Carbon Film Axial Lead',
      };
      functionDescription =
          'Input current-limiting resistor. Placed between V_BB supply and the Transistor Base pin to protect the Base-Emitter junction and set the desired input base current I_B = (V_BB - V_BE) / R1.';
      break;

    case ComponentSpecType.r2:
      title = 'Collector Resistor R2 (R_C)';
      subtitle = 'Carbon Film Fixed Resistor';
      icon = Icons.linear_scale;
      themeColor = const Color(0xFF9333EA);
      specs = {
        'Nominal Resistance': '1,000 Ω (1 kΩ)',
        'Tolerance': '±5% (Gold tolerance band)',
        'Color Bands': 'Brown (1) • Black (0) • Red (×100) • Gold (±5%)',
        'Power Rating': '0.25 W (1/4 Watt)',
        'Maximum Working Voltage': '250 V',
        'Construction': 'Carbon Film Axial Lead',
      };
      functionDescription =
          'Collector load resistor. Converts the collector current I_C into an output voltage swing V_CE across the transistor terminals (V_CE = V_CC - I_C · R2) and defines the DC load line.';
      break;

    case ComponentSpecType.vbb:
      title = 'V_BB Regulated DC Supply';
      subtitle = 'Input Base Bias Voltage Source';
      icon = Icons.electric_bolt;
      themeColor = Colors.amber.shade700;
      specs = {
        'Voltage Range': '0.0 V – 5.0 V DC (Continuously Variable)',
        'Resolution': '0.01 V Potentiometer Control',
        'Max Current Output': '1.0 A',
        'Terminal Type': '5-Way Binding Post (Amber Shroud)',
      };
      functionDescription =
          'Provides adjustable forward-bias voltage to the Base-Emitter junction to vary I_B for measuring Input Characteristics (I_B vs V_BE).';
      break;

    case ComponentSpecType.vcc:
      title = 'V_CC Regulated DC Supply';
      subtitle = 'Collector-Emitter DC Voltage Source';
      icon = Icons.bolt;
      themeColor = Colors.redAccent;
      specs = {
        'Voltage Range': '0.0 V – 15.0 V DC (Continuously Variable)',
        'Resolution': '0.1 V Potentiometer Control',
        'Max Current Output': '2.0 A',
        'Terminal Type': '5-Way Binding Post (Red Shroud)',
      };
      functionDescription =
          'Provides variable output loop voltage across the collector-emitter path to observe Output Characteristics (I_C vs V_CE) across Cutoff, Active, and Saturation regions.';
      break;

    case ComponentSpecType.gnd:
      title = 'Common Ground (GND)';
      subtitle = '0V Reference Potential Rail';
      icon = Icons.south;
      themeColor = Colors.green;
      specs = {
        'Reference Potential': '0.0 V (Zero Volt Datum)',
        'Bus Type': 'Continuous Ground Plane Rail',
        'Terminal Type': '5-Way Binding Post (Green Shroud)',
      };
      functionDescription =
          'Provides common return reference linking Transistor Emitter, V_BB(-) return, and V_CC(-) return, defining the Common Emitter (CE) configuration.';
      break;

    case ComponentSpecType.ammeterIb:
      title = 'Base Microammeter (I_B)';
      subtitle = 'DC Series Microammeter (µA)';
      icon = Icons.speed;
      themeColor = Colors.amber.shade800;
      specs = {
        'Measurement Parameter': 'Base Current (I_B)',
        'Full Scale Range': '0 – 200 µA DC',
        'Resolution / Accuracy': '0.1 µA (±1% F.S.)',
        'Internal Shunt Burden': '< 50 Ω (Low burden voltage)',
        'Connection Type': 'In-Line Series between R1 and Base (B)',
      };
      functionDescription =
          'Measures the microscopic base drive current controlling the transistor. Essential for plotting Input Characteristic curves (I_B vs V_BE) and finding base dynamic resistance.';
      break;

    case ComponentSpecType.ammeterIc:
      title = 'Collector Milliammeter (I_C)';
      subtitle = 'DC Series Milliammeter (mA)';
      icon = Icons.speed;
      themeColor = Colors.green.shade700;
      specs = {
        'Measurement Parameter': 'Collector Current (I_C)',
        'Full Scale Range': '0 – 50 mA DC',
        'Resolution / Accuracy': '0.01 mA (±1% F.S.)',
        'Internal Shunt Burden': '< 0.5 Ω (Negligible voltage drop)',
        'Connection Type': 'In-Line Series between R2 and Collector (C)',
      };
      functionDescription =
          'Measures the amplified collector output current. Key instrument for Output Characteristics (I_C vs V_CE) and verifying current gain β = I_C / I_B.';
      break;

    case ComponentSpecType.voltmeterVbe:
      title = 'Base-Emitter Voltmeter (V_BE)';
      subtitle = 'DC Digital Voltmeter (High-Z)';
      icon = Icons.speed;
      themeColor = Colors.cyan.shade700;
      specs = {
        'Measurement Parameter': 'Base-to-Emitter Potential (V_BE)',
        'Full Scale Range': '0.000 – 2.000 V DC',
        'Input Impedance': '10 MΩ (Negligible loading effect)',
        'Resolution': '1 mV (0.001 V)',
        'Connection Type': 'Parallel Probe across Base (+) and GND (-)',
      };
      functionDescription =
          'Measures the forward-bias junction potential across the Base-Emitter silicon diode, capturing the ~0.65V knee voltage in active conduction.';
      break;

    case ComponentSpecType.voltmeterVce:
      title = 'Collector-Emitter Voltmeter (V_CE)';
      subtitle = 'DC Digital Voltmeter (High-Z)';
      icon = Icons.speed;
      themeColor = Colors.teal.shade700;
      specs = {
        'Measurement Parameter': 'Collector-to-Emitter Potential (V_CE)',
        'Full Scale Range': '0.00 – 20.00 V DC',
        'Input Impedance': '10 MΩ (Negligible loading effect)',
        'Resolution': '10 mV (0.01 V)',
        'Connection Type': 'Parallel Probe across Collector (+) and GND (-)',
      };
      functionDescription =
          'Measures terminal voltage across the output collector-emitter loop, defining the horizontal axis of the output characteristic curves and identifying Cutoff vs Saturation vs Active region.';
      break;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: themeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Technical Specifications:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  for (final entry in specs.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.key != specs.keys.last)
                      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: themeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      functionDescription,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: themeColor, visualDensity: VisualDensity.compact),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}

class _RealisticZoomedBreadboardPainter extends CustomPainter {
  final List<HandWire> wires;
  final BoardPinId? selectedPin;
  final BoardPinId? draggingFromPin;
  final Offset? currentDragPos;
  final Color dragWireColor;
  final bool isDark;
  final bool isLarge;
  final Map<ComponentSpecType, Offset>? customComponentPositions;
  final ComponentSpecType? draggingComponent;

  _RealisticZoomedBreadboardPainter({
    required this.wires,
    required this.selectedPin,
    required this.draggingFromPin,
    required this.currentDragPos,
    required this.dragWireColor,
    required this.isDark,
    this.isLarge = false,
    this.customComponentPositions,
    this.draggingComponent,
  });

  Map<ComponentSpecType, Offset> _getComponentPositions(Size size) {
    if (customComponentPositions != null) {
      return customComponentPositions!;
    }
    return _getDefaultComponentPositions(size, isLarge: isLarge);
  }


  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final compPositions = _getComponentPositions(size);
    final pinMap = _calculatePinPositionsFromComponents(compPositions, size, isLarge: isLarge);
    final bool isConnectingWire = selectedPin != null || draggingFromPin != null;

    // ==========================================
    // 1. REALISTIC BREADBOARD CHASSIS
    // ==========================================
    final boardRect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);

    final boardShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 3)), const Radius.circular(10)),
      boardShadow,
    );

    final boardPaint = Paint()..color = isDark ? const Color(0xFF1E2430) : const Color(0xFFF7F4EB);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(10)), boardPaint);

    final rimPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(10)), rimPaint);

    final tabPaint = Paint()..color = isDark ? const Color(0xFF191F2B) : const Color(0xFFEDE9DF);
    for (double ty = boardRect.top + 30; ty < boardRect.bottom - 30; ty += 40) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(boardRect.left - 3, ty, 5, 14), const Radius.circular(2)), tabPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(boardRect.right - 2, ty, 5, 14), const Radius.circular(2)), tabPaint);
    }

    final topRedBus = Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.6)..strokeWidth = 1.8;
    final topBlueBus = Paint()..color = const Color(0xFF1E88E5).withValues(alpha: 0.6)..strokeWidth = 1.8;
    canvas.drawLine(Offset(boardRect.left + 24, boardRect.top + 16), Offset(boardRect.right - 24, boardRect.top + 16), topRedBus);
    canvas.drawLine(Offset(boardRect.left + 24, boardRect.top + 22), Offset(boardRect.right - 24, boardRect.top + 22), topBlueBus);

    final troughY = isLarge ? size.height * 0.49 : 118.0;
    final troughRect = Rect.fromLTWH(boardRect.left + 16, troughY, boardRect.width - 32, isLarge ? 10 : 8);
    final troughPaint = Paint()..color = isDark ? const Color(0xFF141923) : const Color(0xFFE2DDD2);
    canvas.drawRRect(RRect.fromRectAndRadius(troughRect, const Radius.circular(2)), troughPaint);

    final bottomGndBus = Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.65)..strokeWidth = 2.0;
    canvas.drawLine(Offset(boardRect.left + 24, boardRect.bottom - 18), Offset(boardRect.right - 24, boardRect.bottom - 18), bottomGndBus);

    final holePaint = Paint()..color = isDark ? const Color(0xFF0F141C) : const Color(0xFF334155);
    final clipPaint = Paint()..color = isDark ? Colors.white24 : Colors.grey.shade400;

    final double stepX = isLarge ? 18.0 : 15.0;
    final double stepY = isLarge ? 16.0 : 13.0;

    for (double x = boardRect.left + 28; x <= boardRect.right - 28; x += stepX) {
      for (double y = boardRect.top + 34; y <= boardRect.bottom - 30; y += stepY) {
        if ((y - troughY).abs() <= (isLarge ? 12 : 7)) continue;

        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 3.4, height: 3.4), const Radius.circular(0.8)),
          holePaint,
        );
        canvas.drawCircle(Offset(x, y), 0.8, clipPaint);
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, Offset pos, Color color, double fontSize, {bool bold = false}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos);
    }

    drawText('+', Offset(boardRect.left + 14, boardRect.top + 10), const Color(0xFFE53935), 9, bold: true);
    drawText('-', Offset(boardRect.left + 15, boardRect.top + 17), const Color(0xFF1E88E5), 9, bold: true);
    drawText('+', Offset(boardRect.right - 20, boardRect.top + 10), const Color(0xFFE53935), 9, bold: true);
    drawText('-', Offset(boardRect.right - 20, boardRect.top + 17), const Color(0xFF1E88E5), 9, bold: true);
    drawText('GND BUS', Offset(centerX - 24, boardRect.bottom - 15), const Color(0xFF2E7D32), 8.5, bold: true);

    // ==========================================
    // 2. REALISTIC COMPONENTS & 3D PULL-OUT VISUALS
    // ==========================================

    // Helper: Draw realistic socket hole with contact clip inside (revealed when pin is pulled out)
    void drawEmptySocketHole(Offset pos) {
      // Cavity shadow
      canvas.drawCircle(
        pos,
        isLarge ? 4.2 : 3.4,
        Paint()..color = isDark ? const Color(0xFF0A0E17) : const Color(0xFF1E293B),
      );
      // Spring contact clip visible inside hole
      canvas.drawCircle(
        pos,
        isLarge ? 2.0 : 1.5,
        Paint()..color = const Color(0xFFC5A059).withValues(alpha: 0.75),
      );
      // Socket rim bevel
      canvas.drawCircle(
        pos,
        isLarge ? 5.2 : 4.2,
        Paint()
          ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Helper: Draw realistic through-hole shiny pin leg pulled out of breadboard
    void drawRealisticExposedPin({
      required Offset topExit,
      required Offset socketPos,
      double pinLengthFraction = 0.88,
      Color baseColor = const Color(0xFFCBD5E1),
      Color shineColor = Colors.white,
      double width = 2.4,
    }) {
      final pinTip = Offset(
        socketPos.dx,
        topExit.dy + (socketPos.dy - topExit.dy) * pinLengthFraction,
      );

      // Pin drop shadow on breadboard
      final pinShadow = Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)
        ..strokeWidth = width + 1.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawLine(
        topExit.translate(isLarge ? 3 : 2, isLarge ? 4 : 3),
        pinTip.translate(isLarge ? 3 : 2, isLarge ? 4 : 3),
        pinShadow,
      );

      // Main metallic core shaft
      final shaftPaint = Paint()
        ..color = baseColor
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(topExit, pinTip, shaftPaint);

      // Specular reflection / metallic highlight line along the pin length
      final shinePaint = Paint()
        ..color = shineColor.withValues(alpha: 0.85)
        ..strokeWidth = width * 0.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        topExit.translate(-width * 0.2, 0),
        pinTip.translate(-width * 0.2, 0),
        shinePaint,
      );

      // Chamfered / beveled pin tip at bottom end
      final tipPaint = Paint()..color = const Color(0xFF94A3B8);
      canvas.drawCircle(pinTip, width * 0.65, tipPaint);
      canvas.drawCircle(pinTip, width * 0.35, Paint()..color = Colors.white70);
    }

    void drawRealisticResistor(Offset center, String label) {
      final compType = label == 'R1' ? ComponentSpecType.r1 : ComponentSpecType.r2;
      final bool isLifted = draggingComponent == compType;

      final inPin = pinMap[label == 'R1' ? BoardPinId.r1In : BoardPinId.r2In]!;
      final outPin = pinMap[label == 'R1' ? BoardPinId.r1Out : BoardPinId.r2Out]!;

      final double rWidth = (isLarge ? 42.0 : 36.0) * (isLifted ? 1.08 : 1.0);
      final double rHeight = (isLarge ? 14.0 : 12.0) * (isLifted ? 1.08 : 1.0);
      final visualCenter = isLifted ? center.translate(0, isLarge ? -14.0 : -10.0) : center;

      if (isLifted) {
        // Ground footprint / detached soft shadow on breadboard surface
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center.translate(0, isLarge ? 9.0 : 7.0), width: rWidth + 12, height: rHeight + 4),
            const Radius.circular(8),
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: isDark ? 0.40 : 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0),
        );

        // Empty socket holes on breadboard where pins were pulled out
        drawEmptySocketHole(inPin);
        drawEmptySocketHole(outPin);

        // Horizontal axial leads coming out of resistor body
        final leadPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final leftBend = Offset(inPin.dx, visualCenter.dy);
        final rightBend = Offset(outPin.dx, visualCenter.dy);

        canvas.drawLine(Offset(visualCenter.dx - (rWidth / 2), visualCenter.dy), leftBend, leadPaint);
        canvas.drawLine(Offset(visualCenter.dx + (rWidth / 2), visualCenter.dy), rightBend, leadPaint);

        // Specular shine on horizontal leads
        final leadShine = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(visualCenter.dx - (rWidth / 2), visualCenter.dy - 0.6), leftBend.translate(0, -0.6), leadShine);
        canvas.drawLine(Offset(visualCenter.dx + (rWidth / 2), visualCenter.dy - 0.6), rightBend.translate(0, -0.6), leadShine);

        // Bent 90° solder elbows
        canvas.drawCircle(leftBend, 1.8, Paint()..color = const Color(0xFF94A3B8));
        canvas.drawCircle(rightBend, 1.8, Paint()..color = const Color(0xFF94A3B8));

        // VERTICAL EXPOSED SHINY PINS descending from bend towards sockets!
        drawRealisticExposedPin(
          topExit: leftBend,
          socketPos: inPin,
          pinLengthFraction: 0.88,
          width: 2.5,
        );
        drawRealisticExposedPin(
          topExit: rightBend,
          socketPos: outPin,
          pinLengthFraction: 0.88,
          width: 2.5,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 3), width: rWidth + 4, height: rHeight),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );

        final leadPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final leftPath = Path()
          ..moveTo(center.dx - (rWidth / 2), center.dy)
          ..lineTo(inPin.dx, inPin.dy);
        canvas.drawPath(leftPath, leadPaint);

        final rightPath = Path()
          ..moveTo(center.dx + (rWidth / 2), center.dy)
          ..lineTo(outPin.dx, outPin.dy);
        canvas.drawPath(rightPath, leadPaint);
      }

      final rRect = Rect.fromCenter(center: visualCenter, width: rWidth, height: rHeight);
      final bodyPaint = Paint()..color = const Color(0xFFDEB887);
      canvas.drawRRect(RRect.fromRectAndRadius(rRect, const Radius.circular(5)), bodyPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: isLifted ? 0.55 : 0.38)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(rRect.left + 3, rRect.top + 2), Offset(rRect.right - 3, rRect.top + 2), highlightPaint);

      final capPaint = Paint()..color = const Color(0xFFC89D66);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rRect.left - 1, rRect.top - 1, 5, rHeight + 2), const Radius.circular(2.5)), capPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rRect.right - 4, rRect.top - 1, 5, rHeight + 2), const Radius.circular(2.5)), capPaint);

      void drawBand(double xOffset, Color bandColor) {
        canvas.drawRect(Rect.fromLTWH(visualCenter.dx + xOffset, rRect.top - 0.5, 3.4, rHeight + 1), Paint()..color = bandColor);
      }

      drawBand(-11, const Color(0xFF5D4037));
      drawBand(-4, Colors.black87);
      drawBand(3, const Color(0xFFD32F2F));
      drawBand(11, const Color(0xFFFFD700));

      drawText(label, Offset(visualCenter.dx - 8, visualCenter.dy - 19), isDark ? Colors.white70 : const Color(0xFF4A3525), isLarge ? 9.5 : 8.5, bold: true);
    }

    void drawRealisticMeter(Offset center, String symbol, String label, Color accentColor, {bool isAmmeter = true}) {
      final compType = isAmmeter
          ? (symbol == 'µA' ? ComponentSpecType.ammeterIb : ComponentSpecType.ammeterIc)
          : (label == 'V_BE' ? ComponentSpecType.voltmeterVbe : ComponentSpecType.voltmeterVce);
      final bool isLifted = draggingComponent == compType;

      final double baseR = isLarge ? 20.0 : 16.0;
      final double r = baseR * (isLifted ? 1.08 : 1.0);
      final visualCenter = isLifted ? center.translate(0, isLarge ? -14.0 : -10.0) : center;

      final inPin = isAmmeter ? pinMap[symbol == 'µA' ? BoardPinId.ammeterIbIn : BoardPinId.ammeterIcIn]! : null;
      final outPin = isAmmeter ? pinMap[symbol == 'µA' ? BoardPinId.ammeterIbOut : BoardPinId.ammeterIcOut]! : null;
      final plusPin = !isAmmeter ? pinMap[label == 'V_BE' ? BoardPinId.voltmeterVbePlus : BoardPinId.voltmeterVcePlus]! : null;
      final minusPin = !isAmmeter ? pinMap[label == 'V_BE' ? BoardPinId.voltmeterVbeMinus : BoardPinId.voltmeterVceMinus]! : null;

      if (isLifted) {
        // Ground footprint / detached soft shadow on breadboard surface
        canvas.drawCircle(
          center.translate(0, isLarge ? 9.0 : 7.0),
          r + 3,
          Paint()
            ..color = Colors.black.withValues(alpha: isDark ? 0.42 : 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.5),
        );

        if (isAmmeter) {
          drawEmptySocketHole(inPin!);
          drawEmptySocketHole(outPin!);

          // Dual exposed golden brass terminal header prongs extending downwards into sockets
          final leftProngExit = Offset(visualCenter.dx - r * 0.65, visualCenter.dy + r * 0.35);
          final rightProngExit = Offset(visualCenter.dx + r * 0.65, visualCenter.dy + r * 0.35);

          drawRealisticExposedPin(
            topExit: leftProngExit,
            socketPos: inPin,
            pinLengthFraction: 0.88,
            baseColor: const Color(0xFFE0A938), // Golden brass
            shineColor: const Color(0xFFFEF08A),
            width: 2.8,
          );
          drawRealisticExposedPin(
            topExit: rightProngExit,
            socketPos: outPin,
            pinLengthFraction: 0.88,
            baseColor: const Color(0xFFE0A938),
            shineColor: const Color(0xFFFEF08A),
            width: 2.8,
          );
        } else {
          drawEmptySocketHole(plusPin!);
          drawEmptySocketHole(minusPin!);

          // Vertical voltmeter probe pins
          final topProngExit = Offset(visualCenter.dx - 5.0, visualCenter.dy + r * 0.35);
          final bottomProngExit = Offset(visualCenter.dx + 5.0, visualCenter.dy + r * 0.35);

          drawRealisticExposedPin(
            topExit: topProngExit,
            socketPos: plusPin,
            pinLengthFraction: 0.88,
            baseColor: const Color(0xFFCBD5E1), // Nickel plated probe pins
            shineColor: Colors.white,
            width: 2.6,
          );
          drawRealisticExposedPin(
            topExit: bottomProngExit,
            socketPos: minusPin,
            pinLengthFraction: 0.88,
            baseColor: const Color(0xFFCBD5E1),
            shineColor: Colors.white,
            width: 2.6,
          );
        }
      } else {
        // Leads to pin terminals
        final meterLeadPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        if (isAmmeter) {
          canvas.drawLine(Offset(center.dx - r, center.dy), inPin!, meterLeadPaint);
          canvas.drawLine(Offset(center.dx + r, center.dy), outPin!, meterLeadPaint);
        } else {
          canvas.drawLine(Offset(center.dx, center.dy - r), plusPin!, meterLeadPaint);
          canvas.drawLine(Offset(center.dx, center.dy + r), minusPin!, meterLeadPaint);
        }

        // Resting Shadow
        canvas.drawCircle(
          center.translate(0, 3),
          r,
          Paint()
            ..color = Colors.black.withValues(alpha: isDark ? 0.40 : 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Bezel
      final bezelPaint = Paint()..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF334155);
      canvas.drawCircle(visualCenter, r, bezelPaint);

      final rimBorder = Paint()
        ..color = accentColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLarge ? 2.0 : 1.5;
      canvas.drawCircle(visualCenter, r, rimBorder);

      // Dial face
      final dialPaint = Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
      canvas.drawCircle(visualCenter, r - (isLarge ? 2.5 : 2.0), dialPaint);

      // Gauge arc
      final arcPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: visualCenter, radius: r - 5),
        math.pi * 0.8,
        math.pi * 1.4,
        false,
        arcPaint,
      );

      // Symbol
      final symPainter = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: accentColor,
            fontSize: isLarge ? 11 : 9.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      symPainter.paint(canvas, Offset(visualCenter.dx - symPainter.width / 2, visualCenter.dy - symPainter.height / 2 - 2));

      // Subtitle Label
      final lblPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: isLarge ? 8.5 : 7.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lblPainter.paint(canvas, Offset(visualCenter.dx - lblPainter.width / 2, visualCenter.dy + r + 2));
    }

    final r1Center = compPositions[ComponentSpecType.r1]!;
    final r2Center = compPositions[ComponentSpecType.r2]!;
    drawRealisticResistor(r1Center, 'R1');
    drawRealisticResistor(r2Center, 'R2');

    // Series Ammeters
    final ammeterIbCenter = compPositions[ComponentSpecType.ammeterIb]!;
    drawRealisticMeter(ammeterIbCenter, 'µA', 'I_B', Colors.amberAccent.shade700, isAmmeter: true);

    final ammeterIcCenter = compPositions[ComponentSpecType.ammeterIc]!;
    drawRealisticMeter(ammeterIcCenter, 'mA', 'I_C', Colors.greenAccent.shade700, isAmmeter: true);

    // Parallel Voltmeters
    final vbeCenter = compPositions[ComponentSpecType.voltmeterVbe]!;
    drawRealisticMeter(vbeCenter, 'V', 'V_BE', const Color(0xFF00B4D8), isAmmeter: false);

    final vceCenter = compPositions[ComponentSpecType.voltmeterVce]!;
    drawRealisticMeter(vceCenter, 'V', 'V_CE', const Color(0xFF0077B6), isAmmeter: false);

    // BC547 Transistor
    void drawRealisticTransistor(Offset center) {
      final bool isLifted = draggingComponent == ComponentSpecType.bjt;

      final double baseWidth = isLarge ? 42.0 : 36.0;
      final double baseHeight = isLarge ? 32.0 : 28.0;
      final double to92Width = baseWidth * (isLifted ? 1.08 : 1.0);
      final double to92Height = baseHeight * (isLifted ? 1.08 : 1.0);
      final visualCenter = isLifted ? center.translate(0, isLarge ? -16.0 : -12.0) : center;

      final bjtPins = [
        pinMap[BoardPinId.bjtBase]!,
        pinMap[BoardPinId.bjtEmitter]!,
        pinMap[BoardPinId.bjtCollector]!,
      ];

      if (isLifted) {
        // Detached soft drop shadow on breadboard
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center.translate(0, isLarge ? 9.0 : 7.0), width: to92Width + 10, height: to92Height + 6),
            const Radius.circular(8),
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );

        // Empty socket holes on breadboard
        drawEmptySocketHole(bjtPins[0]);
        drawEmptySocketHole(bjtPins[1]);
        drawEmptySocketHole(bjtPins[2]);

        // Three exposed shiny metallic pins (TO-92 through-hole legs)
        final baseExit = Offset(visualCenter.dx - 12, visualCenter.dy + (to92Height / 2));
        final emitterExit = Offset(visualCenter.dx + 12, visualCenter.dy + (to92Height / 2));
        final collectorExit = Offset(visualCenter.dx, visualCenter.dy - (to92Height / 2));

        drawRealisticExposedPin(
          topExit: baseExit,
          socketPos: bjtPins[0],
          pinLengthFraction: 0.88,
          width: 2.6,
        );
        drawRealisticExposedPin(
          topExit: emitterExit,
          socketPos: bjtPins[1],
          pinLengthFraction: 0.88,
          width: 2.6,
        );
        drawRealisticExposedPin(
          topExit: collectorExit,
          socketPos: bjtPins[2],
          pinLengthFraction: 0.88,
          width: 2.6,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: to92Width + 4, height: to92Height),
            const Radius.circular(6),
          ),
          Paint()..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        final leadPaint = Paint()
          ..color = const Color(0xFFE2E8F0)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(center.dx - 12, center.dy + (to92Height / 2)), bjtPins[0], leadPaint);
        canvas.drawLine(Offset(center.dx + 12, center.dy + (to92Height / 2)), bjtPins[1], leadPaint);
        canvas.drawLine(Offset(center.dx, center.dy - (to92Height / 2)), bjtPins[2], leadPaint);
      }

      final bodyRect = Rect.fromCenter(center: visualCenter, width: to92Width, height: to92Height);
      final bodyPath = Path()
        ..moveTo(bodyRect.left + 4, bodyRect.bottom)
        ..lineTo(bodyRect.right - 4, bodyRect.bottom)
        ..arcToPoint(Offset(bodyRect.right, bodyRect.bottom - 4), radius: const Radius.circular(4))
        ..lineTo(bodyRect.right, bodyRect.top + 8)
        ..arcToPoint(Offset(bodyRect.left, bodyRect.top + 8), radius: const Radius.circular(18))
        ..lineTo(bodyRect.left, bodyRect.bottom - 4)
        ..arcToPoint(Offset(bodyRect.left + 4, bodyRect.bottom), radius: const Radius.circular(4))
        ..close();

      canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF1E2229));

      final plasticHighlight = Paint()
        ..color = Colors.white.withValues(alpha: isLifted ? 0.32 : 0.18)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromLTWH(bodyRect.left + 4, bodyRect.top + 2, to92Width - 8, 14), math.pi, math.pi, false, plasticHighlight);

      drawText('BC547B', Offset(visualCenter.dx - 16, visualCenter.dy - 6), Colors.white.withValues(alpha: 0.85), isLarge ? 8.5 : 7.5, bold: true);
      drawText('NPN', Offset(visualCenter.dx - 8, visualCenter.dy + 4), Colors.white54, isLarge ? 7.5 : 6.5, bold: true);

      final activePin = selectedPin ?? draggingFromPin;
      if (activePin == BoardPinId.bjtBase) {
        drawText('B', Offset(bjtPins[0].dx - 6, bjtPins[0].dy + 6), const Color(0xFF29B6F6), isLarge ? 10 : 9, bold: true);
      } else if (activePin == BoardPinId.bjtEmitter) {
        drawText('E', Offset(bjtPins[1].dx - 2, bjtPins[1].dy + 6), const Color(0xFF66BB6A), isLarge ? 10 : 9, bold: true);
      } else if (activePin == BoardPinId.bjtCollector) {
        drawText('C', Offset(bjtPins[2].dx - 4, bjtPins[2].dy - 16), const Color(0xFFAB47BC), isLarge ? 10 : 9, bold: true);
      }
    }

    drawRealisticTransistor(compPositions[ComponentSpecType.bjt]!);

    if (draggingComponent != null && compPositions.containsKey(draggingComponent!)) {
      final activeCenter = compPositions[draggingComponent!]!;
      canvas.drawCircle(
        activeCenter,
        isLarge ? 30 : 24,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Binding posts
    void drawBindingPost(Offset pos, Color color, String label, ComponentSpecType compType, {bool isRight = false}) {
      final bool isLifted = draggingComponent == compType;
      final double baseR = isLarge ? 12.0 : 10.0;
      final double r = baseR * (isLifted ? 1.1 : 1.0);
      final visualPos = isLifted ? pos.translate(0, isLarge ? -12.0 : -8.0) : pos;

      final terminalPinId = compType == ComponentSpecType.vbb
          ? BoardPinId.vbbPlus
          : (compType == ComponentSpecType.vcc ? BoardPinId.vccPlus : BoardPinId.commonGnd);
      final terminalPos = pinMap[terminalPinId]!;

      // Realistic metallic strap from post knob to wire socket
      final strapPaint = Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(visualPos, terminalPos, strapPaint);

      if (isLifted) {
        canvas.drawCircle(
          pos.translate(0, isLarge ? 6.0 : 4.0),
          r + 3,
          Paint()
            ..color = Colors.black.withValues(alpha: isDark ? 0.4 : 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        drawEmptySocketHole(pos);

        // Exposed brass mounting shank
        drawRealisticExposedPin(
          topExit: visualPos,
          socketPos: pos,
          pinLengthFraction: 0.9,
          baseColor: const Color(0xFFD4AF37),
          shineColor: const Color(0xFFFFF275),
          width: 3.4,
        );
      }

      final nutPaint = Paint()..color = const Color(0xFFB0BEC5);
      canvas.drawCircle(visualPos, r, nutPaint);
      canvas.drawCircle(visualPos, r - 1.5, Paint()..color = isDark ? const Color(0xFF374151) : const Color(0xFFCFD8DC));

      canvas.drawCircle(visualPos, r - 3.0, Paint()..color = color);
      canvas.drawCircle(visualPos, r - 5.5, Paint()..color = color.withValues(alpha: 0.85));

      canvas.drawCircle(visualPos, 3.4, Paint()..color = const Color(0xFFD4AF37));
      canvas.drawCircle(visualPos, 2.0, Paint()..color = Colors.black);

      final textOffset = isRight
          ? Offset(visualPos.dx - (isLarge ? 38 : 32), visualPos.dy - 5)
          : Offset(visualPos.dx + (isLarge ? 14 : 12), visualPos.dy - 5);
      drawText(label, textOffset, color, isLarge ? 10 : 9, bold: true);
    }

    drawBindingPost(compPositions[ComponentSpecType.vbb]!, const Color(0xFFFF8F00), 'VBB', ComponentSpecType.vbb);
    drawBindingPost(compPositions[ComponentSpecType.vcc]!, const Color(0xFFE53935), 'VCC', ComponentSpecType.vcc, isRight: true);
    drawBindingPost(compPositions[ComponentSpecType.gnd]!, const Color(0xFF2E7D32), 'GND', ComponentSpecType.gnd);

    // ==========================================
    // 3. DRAW REALISTIC FLEXIBLE WIRES
    // ==========================================
    void drawRealisticWire(Offset start, Offset end, Color color, {bool isLiveDrag = false}) {
      final double distance = (end - start).distance;
      final double midX = (start.dx + end.dx) / 2;
      final double sag = isLiveDrag ? 8.0 : math.min(isLarge ? 48.0 : 36.0, distance * 0.22 + 6.0);
      final double controlY = math.max(start.dy, end.dy) + sag;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(midX, controlY, end.dx, end.dy);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)
        ..strokeWidth = isLarge ? 4.0 : 3.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawPath(path, shadowPaint);

      final outerPaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = isLarge ? 3.2 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, outerPaint);

      final wirePaint = Paint()
        ..color = color
        ..strokeWidth = isLarge ? 2.2 : 1.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, wirePaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.36)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, highlightPaint);

      void drawBoot(Offset pt) {
        canvas.drawCircle(pt, isLarge ? 4.0 : 3.2, Paint()..color = const Color(0xFF263238));
        canvas.drawCircle(pt, isLarge ? 2.4 : 1.9, Paint()..color = color);
        canvas.drawCircle(pt, 1.0, Paint()..color = const Color(0xFFFFD700));
      }

      drawBoot(start);
      drawBoot(end);
    }

    for (final w in wires) {
      final p1 = pinMap[w.from];
      final p2 = pinMap[w.to];
      if (p1 != null && p2 != null) {
        drawRealisticWire(p1, p2, w.color);
      }
    }

    if (draggingFromPin != null && currentDragPos != null) {
      final p1 = pinMap[draggingFromPin!];
      if (p1 != null) {
        drawRealisticWire(p1, currentDragPos!, dragWireColor, isLiveDrag: true);
      }
    }

    // ==========================================
    // 4. DRAW CONTACT PINS & MAGNETIC SNAP RINGS
    // ==========================================
    if (isConnectingWire) {
      pinMap.forEach((id, pos) {
        final isSelected = selectedPin == id || draggingFromPin == id;
        final isHovered = draggingFromPin != null &&
            draggingFromPin != id &&
            currentDragPos != null &&
            (currentDragPos! - pos).distance <= (isLarge ? 24.0 : 18.0);

        // Only the selected one (or actively hovered snap target) is popped!
        if (!isSelected && !isHovered) return;

        final haloPaint = Paint()
          ..color = (isHovered ? Colors.greenAccent : const Color(0xFFFFD54F)).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isLarge ? 5.5 : 4.5;
        canvas.drawCircle(pos, isLarge ? 14 : 11, haloPaint);

        final ringPaint = Paint()..color = isHovered ? Colors.greenAccent : const Color(0xFFC5A059);
        canvas.drawCircle(pos, isLarge ? 6.8 : 5.5, ringPaint);

        final socketPaint = Paint()..color = Colors.black87;
        canvas.drawCircle(pos, isLarge ? 3.6 : 3.0, socketPaint);

        final centerPaint = Paint()..color = isSelected ? const Color(0xFFFFE082) : Colors.white;
        canvas.drawCircle(pos, 1.6, centerPaint);
      });
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticZoomedBreadboardPainter oldDelegate) => true;
}
