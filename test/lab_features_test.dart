import 'package:flutter_test/flutter_test.dart';
import 'package:electronics_app/models/breadboard_models.dart';
import 'package:electronics_app/models/prelab_calculation.dart';
import 'package:electronics_app/models/slope_measurement.dart';
import 'package:electronics_app/services/circuit_validator.dart';

void main() {
  group('CircuitValidator Tests', () {
    test('Standard wiring is completely valid', () {
      final wires = CircuitValidator.getStandardWiring();
      final result = CircuitValidator.validate(wires);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Missing emitter ground halts circuit with diagnostic error', () {
      final wires = [
        const BreadboardWire(id: '1', from: BreadboardTerminal.vbbGnd, to: BreadboardTerminal.commonGnd),
        const BreadboardWire(id: '2', from: BreadboardTerminal.vccGnd, to: BreadboardTerminal.commonGnd),
        const BreadboardWire(id: '3', from: BreadboardTerminal.vbbPositive, to: BreadboardTerminal.r1In),
        const BreadboardWire(id: '4', from: BreadboardTerminal.r1Out, to: BreadboardTerminal.bjtBase),
        const BreadboardWire(id: '5', from: BreadboardTerminal.vccPositive, to: BreadboardTerminal.r2In),
        const BreadboardWire(id: '6', from: BreadboardTerminal.r2Out, to: BreadboardTerminal.bjtCollector),
        // Emitter intentionally not grounded
      ];
      final result = CircuitValidator.validate(wires);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Emitter terminal')), isTrue);
    });
  });

  group('PreLabCalculator Tests', () {
    test('Calculates active region DC bias correctly', () {
      final res = PreLabCalculator.calculateDcBias(
        vcc: 10.0,
        rb: 220.0,
        rc: 1.0,
        beta: 150.0,
      );
      expect(res['isValid'], isTrue);
      expect(res['isSaturated'], isFalse);
      expect(res['vCE'], isNotNull);
      expect(res['iC_mA'], isNotNull);
    });

    test('Percent error calculation is accurate', () {
      final err = PreLabCalculator.percentError(10.0, 9.5);
      expect(err, closeTo(5.0, 0.01));
    });
  });

  group('SlopeMeasurement Tests', () {
    test('Calculates Rin with delta Vbe and delta Ib correctly', () {
      // Point 1: (0.65 V, 100 uA), Point 2: (0.75 V, 500 uA)
      final m = SlopeMeasurement(
        point1: const Offset(0.65, 100.0),
        point2: const Offset(0.75, 500.0),
        mode: SlopeMode.inputResistance,
      );
      // deltaX = 0.10 V, deltaY = 400 uA -> Rin = (0.10 / 400) * 10^6 = 250 Ohms
      expect(m.calculatedValue, closeTo(250.0, 0.1));
      expect(m.formattedResult, '250.0 Ω');
    });
  });
}
