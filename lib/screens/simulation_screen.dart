import 'package:flutter/material.dart';

/// Screen for BJT Common Emitter virtual simulation and parameter exploration.
/// (Module assigned to Suresh).
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _vbb = 1.0;
  double _vcc = 10.0;
  double _rb = 100.0; // in kΩ
  double _rc = 1.0; // in kΩ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT CE Virtual Simulation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Circuit Parameter Controls',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
          Text('Base Resistance (Rb): ${_rb.toStringAsFixed(0)} kΩ'),
          Slider(
            value: _rb,
            min: 10.0,
            max: 1000.0,
            divisions: 99,
            onChanged: (val) => setState(() => _rb = val),
          ),
          Text('Collector Resistance (Rc): ${_rc.toStringAsFixed(1)} kΩ'),
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
}
