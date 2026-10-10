import 'package:flutter/material.dart';

enum SlopeMode {
  inputResistance, // Rin = delta Vbe / delta Ib (Vce constant)
  outputResistance, // Rout = delta Vce / delta Ic (Ib constant)
  currentGain, // Beta = delta Ic / delta Ib (Vce constant)
}

class SlopeMeasurement {
  final Offset point1;
  final Offset point2;
  final SlopeMode mode;

  const SlopeMeasurement({
    required this.point1,
    required this.point2,
    required this.mode,
  });

  double get deltaX => (point2.dx - point1.dx).abs();
  double get deltaY => (point2.dy - point1.dy).abs();

  /// Calculates dynamic Rin (Ohms), Rout (kOhms), or Beta (dimensionless)
  double get calculatedValue {
    if (deltaY == 0) return 0.0;
    switch (mode) {
      case SlopeMode.inputResistance:
        // x is Vbe (V), y is Ib (uA) -> Rin = delta Vbe / (delta Ib * 10^-6) = (deltaX / deltaY) * 10^6 Ohms
        return (deltaX / deltaY) * 1000000.0;
      case SlopeMode.outputResistance:
        // x is Vce (V), y is Ic (mA) -> Rout = delta Vce / (delta Ic * 10^-3) = (deltaX / deltaY) * 10^3 Ohms = (deltaX / deltaY) kOhms
        if (deltaY == 0) return 999999.0;
        return (deltaX / deltaY); // in kOhms
      case SlopeMode.currentGain:
        // x is Ib (uA), y is Ic (mA) -> Beta = (delta Ic * 10^-3) / (delta Ib * 10^-6) = (deltaY / deltaX) * 1000
        if (deltaX == 0) return 0.0;
        return (deltaY / deltaX) * 1000.0;
    }
  }

  String get formattedResult {
    switch (mode) {
      case SlopeMode.inputResistance:
        final rIn = calculatedValue;
        if (rIn > 1000) {
          return '${(rIn / 1000).toStringAsFixed(2)} kΩ';
        }
        return '${rIn.toStringAsFixed(1)} Ω';
      case SlopeMode.outputResistance:
        final rOutK = calculatedValue;
        return '${rOutK.toStringAsFixed(2)} kΩ';
      case SlopeMode.currentGain:
        return calculatedValue.toStringAsFixed(1);
    }
  }
}
