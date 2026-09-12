/// Model representing a single experimental reading for BJT Input Characteristics
/// (IB vs VBE at constant VCE).
class InputReading {
  final double vbb; // Base supply voltage in Volts (e.g. 0.5V, 1.0V... 5.0V)
  final double vce; // Fixed Collector-Emitter voltage (e.g. 1.0V or 2.0V)
  final double vbe; // Measured Base-Emitter voltage in Volts
  final double ib; // Measured Base current in microamperes (µA)

  const InputReading({
    required this.vbb,
    required this.vce,
    required this.vbe,
    required this.ib,
  });

  Map<String, dynamic> toJson() => {
        'vbb': vbb,
        'vce': vce,
        'vbe': vbe,
        'ib': ib,
      };

  factory InputReading.fromJson(Map<String, dynamic> json) => InputReading(
        vbb: (json['vbb'] as num).toDouble(),
        vce: (json['vce'] as num).toDouble(),
        vbe: (json['vbe'] as num).toDouble(),
        ib: (json['ib'] as num).toDouble(),
      );
}
