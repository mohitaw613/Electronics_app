import 'package:flutter/material.dart';

/// Screen displaying full Experiment 5 theory, circuit schematics, procedures, and pinouts.
/// (Module assigned to Suresh).
class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment 5 Theory & Schematics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            title: '1. Objective',
            color: Colors.blue.shade50,
            icon: Icons.flag,
            child: const Text(
              '1. Design and setup the circuit for BJT in Common Emitter (CE) configuration.\n'
              '2. Measure and plot the Input Characteristics (IB vs VBE) at constant VCE (1V, 2V).\n'
              '3. Measure and plot the Output Characteristics (IC vs VCE) at constant IB (4.3µA, 10µA).\n'
              '4. Determine dynamic input resistance (Rin), output resistance (Rout), and current gain (β).',
              style: TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: '2. Apparatus & Components (BC547)',
            color: Colors.teal.shade50,
            icon: Icons.memory,
            child: const Text(
              '• Transistor: BC547 (NPN Silicon Transistor)\n'
              '• Resistors:\n'
              '   - R1 (Base Resistor): 1kΩ (Input mode), 470kΩ (IB ≈ 10µA), 1MΩ (IB ≈ 4.3µA)\n'
              '   - R2 (Collector Resistor): 1kΩ\n'
              '• Dual DC Power Supply: 0 - 30V DC\n'
              '   - V1 / Vbb: 0 - 5V DC (variable in 0.5V steps)\n'
              '   - V2 / Vcc: 0 - 15V DC (variable in 1.0V steps)\n'
              '• Measuring Meters: Digital Multimeter, Ammeter (µA/mA), Voltmeter',
              style: TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: '3. Input Characteristics (IB vs VBE)',
            color: Colors.purple.shade50,
            icon: Icons.input,
            child: const Text(
              'The input characteristic curve is a plot of Base Current (IB) versus Base-Emitter Voltage (VBE) with Collector-Emitter Voltage (VCE) held constant.\n\n'
              '• Procedure:\n'
              '  1. Fix VCE = 1.0V (or 2.0V).\n'
              '  2. Increase input voltage V1 (Vbb) from 0V to 5V in 0.5V steps.\n'
              '  3. Note corresponding VBE and IB readings.\n'
              '• Curve behavior: Acts like a forward-biased diode. Current is near 0µA until cut-in voltage (~0.65V), then rises exponentially.',
              style: TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: '4. Output Characteristics (IC vs VCE)',
            color: Colors.amber.shade50,
            icon: Icons.output,
            child: const Text(
              'The output characteristic curve is a plot of Collector Current (IC) versus Collector-Emitter Voltage (VCE) with Base Current (IB) held constant.\n\n'
              '• Procedure:\n'
              '  1. Set R1 = 1MΩ for IB = 4.3µA (or R1 = 470kΩ for IB = 10µA).\n'
              '  2. Vary Vcc (V2) from 0V to 10V in steps of 1V.\n'
              '  3. Record IC and VCE.\n'
              '• Operating Regions:\n'
              '  - Saturation Region (VCE < 0.2V): IC rises sharply.\n'
              '  - Active Region (VCE > 0.2V): IC remains almost constant (IC ≈ β · IB).\n'
              '  - Cutoff Region (IB = 0): IC ≈ 0.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
