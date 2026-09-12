/// Model representing a single experimental reading for BJT Output Characteristics
/// (IC vs VCE at constant IB).
class OutputReading {
  final double vcc; // Collector supply voltage in Volts (e.g. 1.0V, 2.0V... 10.0V)
  final double ib; // Fixed Base current in microamperes (e.g. 4.3µA or 10.0µA)
  final double vce; // Measured Collector-Emitter voltage in Volts
  final double ic; // Measured Collector current in milliamperes (mA)

  const OutputReading({
    required this.vcc,
    required this.ib,
    required this.vce,
    required this.ic,
  });

  Map<String, dynamic> toJson() => {
        'vcc': vcc,
        'ib': ib,
        'vce': vce,
        'ic': ic,
      };

  factory OutputReading.fromJson(Map<String, dynamic> json) => OutputReading(
        vcc: (json['vcc'] as num).toDouble(),
        ib: (json['ib'] as num).toDouble(),
        vce: (json['vce'] as num).toDouble(),
        ic: (json['ic'] as num).toDouble(),
      );
}
