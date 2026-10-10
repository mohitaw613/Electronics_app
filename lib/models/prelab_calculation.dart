import 'dart:math' as math;

class PreLabCalculator {
  static Map<String, dynamic> calculateDcBias({
    required double vcc, // in Volts
    required double rb,  // in kOhms
    required double rc,  // in kOhms
    required double beta,
    double vbe = 0.70,   // standard Silicon Vbe forward drop
  }) {
    if (vcc <= 0 || rb <= 0 || rc <= 0 || beta <= 0) {
      return {
        'isValid': false,
        'message': 'Input values must be greater than zero.',
      };
    }

    // 1. Base Current: Ib = (Vcc - Vbe) / Rb
    final double ibUa = vcc > vbe ? ((vcc - vbe) / (rb * 1000.0)) * 1000000.0 : 0.0;

    // 2. Ideal Active Collector Current: Ic = beta * Ib
    final double idealIcMa = (ibUa * beta) / 1000.0;

    // 3. Maximum Saturation Collector Current: Ic(sat) = Vcc / Rc
    final double icSatMa = (vcc / (rc * 1000.0)) * 1000.0;

    final bool isSaturated = idealIcMa >= icSatMa;
    final double icMa = isSaturated ? icSatMa : idealIcMa;

    // 4. Collector Voltage: Vc = Vce = Vcc - (Ic * Rc)
    final double vDropRc = (icMa / 1000.0) * (rc * 1000.0);
    final double vce = isSaturated ? 0.2 : math.max(0.2, vcc - vDropRc);

    final double vb = vbe;
    final double ve = 0.0; // Common Emitter grounded

    return {
      'isValid': true,
      'isSaturated': isSaturated,
      'vB': vb,
      'vC': vce,
      'vE': ve,
      'vCE': vce,
      'iB_uA': ibUa,
      'iC_mA': icMa,
      'operatingState': isSaturated ? 'Saturation Region' : 'Active Region',
    };
  }

  static double percentError(double theoretical, double measured) {
    if (theoretical.abs() < 1e-6) return 0.0;
    return ((measured - theoretical).abs() / theoretical.abs()) * 100.0;
  }
}
