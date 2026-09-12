import 'package:flutter/material.dart';

/// Screen displaying Experiment 5 theory, circuit diagrams, objectives, and formulae.
/// (Module assigned to Suresh).
class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment 5 Theory'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Experiment 5: Input & Output Characteristics of BJT (CE)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Objective:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text(
            '1. Design the circuit diagram for Common Emitter configuration.\n'
            '2. Take readings and draw Input & Output characteristics curves.\n'
            '3. Determine dynamic input resistance (Rin), output resistance (Rout), and current gain (β).',
          ),
          SizedBox(height: 16),
          Text(
            'Components & Apparatus:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text(
            '• Transistor: BC547 (NPN Silicon)\n'
            '• Resistors: 1kΩ, 470kΩ, 1MΩ\n'
            '• Dual DC Power Supply: 0 - 30V (V1/Vbb: 0-5V, V2/Vcc: 0-15V)\n'
            '• Digital Multimeter / Ammeter & Voltmeter\n'
            '• Breadboard & connecting wires',
          ),
          SizedBox(height: 16),
          Text(
            'Key Formulae:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text(
            '• β_dc = IC / IB\n'
            '• β_ac = (ΔIC / ΔIB) at constant VCE\n'
            '• Rin = (ΔVBE / ΔIB) at constant VCE\n'
            '• Rout = (ΔVCE / ΔIC) at constant IB\n'
            '• DC Load Line: VCE = VCC - (IC × RC)',
          ),
        ],
      ),
    );
  }
}
