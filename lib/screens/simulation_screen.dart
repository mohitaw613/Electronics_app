import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/proteus_bjt_circuit.dart';
import 'bjt_3d_viewer_screen.dart';

/// Screen for BJT Common Emitter virtual simulation with circuit layout.
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _vbb = 2.5; // Base supply in Volts (0 - 5V)
  double _vcc = 10.0; // Collector supply in Volts (0 - 15V)
  double _rb = 100.0; // Base resistor in kΩ (10kΩ - 1000kΩ)
  double _rc = 1.0; // Collector resistor in kΩ (0.5kΩ - 5kΩ)
  final double _beta = 150.0; // BC547 nominal DC current gain

  // Semiconductor physics calculations for Silicon BC547 NPN
  double get _vbe {
    if (_vbb <= 0.6) return _vbb;
    return 0.65 + math.min(0.08, (_vbb - 0.6) * 0.02);
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
    if (_ib <= 0.01) return 'CUTOFF REGION (Transistor OFF)';
    if (_vce <= 0.25) return 'SATURATION REGION (Fully ON)';
    return 'ACTIVE REGION (Linear Amplification)';
  }

  Color get _regionColor {
    if (_ib <= 0.01) return Colors.redAccent;
    if (_vce <= 0.25) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT CE Virtual Simulation'),
        actions: [
          IconButton(
            tooltip: 'Transistor Packages & Pinouts',
            icon: const Icon(Icons.memory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Bjt3dViewerScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Operating Region Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _regionColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _regionColor, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: _regionColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _operatingRegion,
                  style: TextStyle(color: _regionColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Circuit Schematic Layout with Live Current Flow
          ProteusBjtCircuit(
            vbb: _vbb,
            vcc: _vcc,
            rb: _rb,
            rc: _rc,
            vbe: _vbe,
            vce: _vce,
            ib: _ib,
            ic: _ic,
            region: _operatingRegion,
          ),
          const SizedBox(height: 14),

          // 3. Digital Multimeter Probes Display (Wrapped in RepaintBoundary for smooth sliding)
          RepaintBoundary(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMeterCard('VBE (Base-Emitter)', '${_vbe.toStringAsFixed(3)} V', Colors.blue, cs, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMeterCard('IB (Base Current)', '${_ib.toStringAsFixed(1)} µA', Colors.amber.shade700, cs, isDark)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildMeterCard('VCE (Collector-Emitter)', '${_vce.toStringAsFixed(2)} V', Colors.teal, cs, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMeterCard('IC (Collector Current)', '${_ic.toStringAsFixed(2)} mA', Colors.green, cs, isDark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // 4. Circuit Controls (High responsiveness)
          RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust Circuit Power Supplies & Resistors',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
                ),
                const SizedBox(height: 10),

                Text(
                  'Base Supply Voltage V1 (Vbb): ${_vbb.toStringAsFixed(1)} V (0V - 5V)',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
                Slider(
                  value: _vbb,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  onChanged: (val) => setState(() => _vbb = val),
                ),

                Text(
                  'Collector Supply Voltage V2 (Vcc): ${_vcc.toStringAsFixed(1)} V (0V - 15V)',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
                Slider(
                  value: _vcc,
                  min: 0.0,
                  max: 15.0,
                  divisions: 150,
                  onChanged: (val) => setState(() => _vcc = val),
                ),

                Text(
                  'Base Resistor R1 (Rb): ${_rb.toStringAsFixed(0)} kΩ (10kΩ - 1000kΩ)',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
                Slider(
                  value: _rb,
                  min: 10.0,
                  max: 1000.0,
                  divisions: 99,
                  onChanged: (val) => setState(() => _rb = val),
                ),

                Text(
                  'Collector Resistor R2 (Rc): ${_rc.toStringAsFixed(1)} kΩ (0.5kΩ - 5kΩ)',
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
                Slider(
                  value: _rc,
                  min: 0.5,
                  max: 5.0,
                  divisions: 45,
                  onChanged: (val) => setState(() => _rc = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard(String label, String value, Color color, ColorScheme cs, bool isDark) {
    return Card(
      elevation: isDark ? 1 : 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? cs.onSurface.withValues(alpha: 0.7) : Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
