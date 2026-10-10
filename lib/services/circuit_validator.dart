import '../models/breadboard_models.dart';

class CircuitValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const CircuitValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  String get summaryMessage {
    if (isValid) {
      return 'Circuit properly wired! Power supply active and simulation enabled.';
    }
    return '${errors.length} wiring error(s) detected. Fix connections to run simulation.';
  }
}

class CircuitValidator {
  /// Evaluates the list of placed jumper wires against required CE circuit topology
  static CircuitValidationResult validate(List<BreadboardWire> wires) {
    final errors = <String>[];
    final warnings = <String>[];

    bool hasWire(BreadboardTerminal a, BreadboardTerminal b) {
      return wires.any((w) => w.connects(a, b));
    }

    // 1. Emitter must be tied to common ground
    final emitterGrounded = hasWire(BreadboardTerminal.bjtEmitter, BreadboardTerminal.commonGnd);
    if (!emitterGrounded) {
      errors.add('Emitter terminal (E) is not connected to Common Ground.');
    }

    // 2. Power supply grounds must be grounded
    final vbbGrounded = hasWire(BreadboardTerminal.vbbGnd, BreadboardTerminal.commonGnd);
    if (!vbbGrounded) {
      errors.add('VBB power supply ground (-) is not connected to Common Ground.');
    }

    final vccGrounded = hasWire(BreadboardTerminal.vccGnd, BreadboardTerminal.commonGnd);
    if (!vccGrounded) {
      errors.add('VCC power supply ground (-) is not connected to Common Ground.');
    }

    // 3. Base supply loop through R1
    final vbbToR1 = hasWire(BreadboardTerminal.vbbPositive, BreadboardTerminal.r1In);
    if (!vbbToR1) {
      errors.add('VBB positive (+) is not connected to Base Resistor R1 input.');
    }

    final r1ToBase = hasWire(BreadboardTerminal.r1Out, BreadboardTerminal.bjtBase);
    if (!r1ToBase) {
      errors.add('Base Resistor R1 output is not connected to Transistor Base pin (B).');
    }

    // 4. Collector supply loop through R2
    final vccToR2 = hasWire(BreadboardTerminal.vccPositive, BreadboardTerminal.r2In);
    if (!vccToR2) {
      errors.add('VCC positive (+) is not connected to Collector Resistor R2 input.');
    }

    final r2ToCollector = hasWire(BreadboardTerminal.r2Out, BreadboardTerminal.bjtCollector);
    if (!r2ToCollector) {
      errors.add('Collector Resistor R2 output is not connected to Transistor Collector pin (C).');
    }

    final bool isValid = errors.isEmpty;
    return CircuitValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Provides standard set of correct wires for the "Auto-Wire / Guided" feature
  static List<BreadboardWire> getStandardWiring() {
    return [
      const BreadboardWire(id: 'w1', from: BreadboardTerminal.bjtEmitter, to: BreadboardTerminal.commonGnd),
      const BreadboardWire(id: 'w2', from: BreadboardTerminal.vbbGnd, to: BreadboardTerminal.commonGnd),
      const BreadboardWire(id: 'w3', from: BreadboardTerminal.vccGnd, to: BreadboardTerminal.commonGnd),
      const BreadboardWire(id: 'w4', from: BreadboardTerminal.vbbPositive, to: BreadboardTerminal.r1In),
      const BreadboardWire(id: 'w5', from: BreadboardTerminal.r1Out, to: BreadboardTerminal.bjtBase),
      const BreadboardWire(id: 'w6', from: BreadboardTerminal.vccPositive, to: BreadboardTerminal.r2In),
      const BreadboardWire(id: 'w7', from: BreadboardTerminal.r2Out, to: BreadboardTerminal.bjtCollector),
    ];
  }
}
