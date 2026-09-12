import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Screen for BJT Common Emitter virtual simulation and parameter exploration.
/// (Module assigned to Suresh).
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _vbb = 2.5; // Base supply in Volts
  double _vcc = 10.0; // Collector supply in Volts
  double _rb = 100.0; // Base resistor in kΩ
  double _rc = 1.0; // Collector resistor in kΩ
  final double _beta = 150.0; // BC547 nominal DC current gain

  // Semiconductor calculations for Silicon BC547
  double get _vbe {
    if (_vbb <= 0.6) return _vbb;
    return 0.65 + math.min(0.1, (_vbb - 0.6) * 0.03);
  }

  double get _ib {
    if (_vbb <= _vbe) return 0.0;
    return ((_vbb - _vbe) / (_rb * 1000.0)) * 1000000.0; // in µA
  }

  double get _ic {
    final activeIc = (_ib * _beta) / 1000.0; // in mA
    final saturationLimit = (_vcc / (_rc * 1000.0)) * 1000.0; // in mA
    return math.min(activeIc, saturationLimit);
  }

  double get _vce {
    final vDrop = (_ic / 1000.0) * (_rc * 1000.0);
    return math.max(0.15, _vcc - vDrop);
  }

  String get _operatingRegion {
    if (_ib <= 0.01) return 'CUTOFF REGION (OFF)';
    if (_vce <= 0.25) return 'SATURATION REGION (Fully ON)';
    return 'ACTIVE REGION (Linear Amplifier)';
  }

  Color get _regionColor {
    if (_ib <= 0.01) return Colors.red;
    if (_vce <= 0.25) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT CE Virtual Simulation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _regionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _regionColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: _regionColor),
                const SizedBox(width: 8),
                Text(
                  _operatingRegion,
                  style: TextStyle(color: _regionColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Virtual Multimeter Readings', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMeterCard('VBE', '${_vbe.toStringAsFixed(3)} V', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildMeterCard('IB', '${_ib.toStringAsFixed(1)} µA', Colors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMeterCard('VCE', '${_vce.toStringAsFixed(2)} V', Colors.teal)),
              const SizedBox(width: 8),
              Expanded(child: _buildMeterCard('IC', '${_ic.toStringAsFixed(2)} mA', Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Adjust Circuit Controls', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Base Supply Voltage (Vbb): ${_vbb.toStringAsFixed(1)} V'),
          Slider(
            value: _vbb,
            min: 0.0,
            max: 5.0,
            divisions: 50,
            onChanged: (val) => setState(() => _vbb = val),
          ),
          Text('Collector Supply Voltage (Vcc): ${_vcc.toStringAsFixed(1)} V'),
          Slider(
            value: _vcc,
            min: 0.0,
            max: 15.0,
            divisions: 150,
            onChanged: (val) => setState(() => _vcc = val),
          ),
          Text('Base Resistor (Rb): ${_rb.toStringAsFixed(0)} kΩ'),
          Slider(
            value: _rb,
            min: 10.0,
            max: 1000.0,
            divisions: 99,
            onChanged: (val) => setState(() => _rb = val),
          ),
          Text('Collector Resistor (Rc): ${_rc.toStringAsFixed(1)} kΩ'),
          Slider(
            value: _rc,
            min: 0.5,
            max: 5.0,
            divisions: 45,
            onChanged: (val) => setState(() => _rc = val),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
