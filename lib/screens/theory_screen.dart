import 'package:flutter/material.dart';
import 'bjt_2d_viewer_screen.dart';

/// Screen displaying full Experiment 5 theory, circuit schematics, procedures, and pinouts.
class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment 5 Theory & Schematics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context: context,
            title: '1. Objective',
            accentColor: Colors.blue,
            icon: Icons.flag,
            child: Text(
              '1. Design and setup the circuit for BJT in Common Emitter (CE) configuration.\n'
              '2. Measure and plot the Input Characteristics (IB vs VBE) at constant VCE (1V, 2V).\n'
              '3. Measure and plot the Output Characteristics (IC vs VCE) at constant IB (4.3µA, 10µA).\n'
              '4. Determine dynamic input resistance (Rin), output resistance (Rout), and current gain (β).',
              style: TextStyle(height: 1.4, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context: context,
            title: '2. Apparatus & Components (BC547)',
            accentColor: Colors.teal,
            icon: Icons.memory,
            child: Text(
              '• Transistor: BC547 (NPN Silicon Transistor)\n'
              '• Resistors:\n'
              '   - R1 (Base Resistor): 1kΩ (Input mode), 470kΩ (IB ≈ 10µA), 1MΩ (IB ≈ 4.3µA)\n'
              '   - R2 (Collector Resistor): 1kΩ\n'
              '• Dual DC Power Supply: 0 - 30V DC\n'
              '   - V1 / Vbb: 0 - 5V DC (variable in 0.5V steps)\n'
              '   - V2 / Vcc: 0 - 15V DC (variable in 1.0V steps)\n'
              '• Measuring Meters: Digital Multimeter, Ammeter (µA/mA), Voltmeter',
              style: TextStyle(height: 1.4, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context: context,
            title: '3. Input Characteristics (IB vs VBE)',
            accentColor: Colors.purple,
            icon: Icons.input,
            child: Text(
              'The input characteristic curve is a plot of Base Current (IB) versus Base-Emitter Voltage (VBE) with Collector-Emitter Voltage (VCE) held constant.\n\n'
              '• Procedure:\n'
              '  1. Fix VCE = 1.0V (or 2.0V).\n'
              '  2. Increase input voltage V1 (Vbb) from 0V to 5V in 0.5V steps.\n'
              '  3. Note corresponding VBE and IB readings.\n'
              '• Curve behavior: Acts like a forward-biased diode. Current is near 0µA until cut-in voltage (~0.65V), then rises exponentially.',
              style: TextStyle(height: 1.4, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context: context,
            title: '4. Output Characteristics (IC vs VCE)',
            accentColor: Colors.amber.shade800,
            icon: Icons.output,
            child: Text(
              'The output characteristic curve is a plot of Collector Current (IC) versus Collector-Emitter Voltage (VCE) with Base Current (IB) held constant.\n\n'
              '• Procedure:\n'
              '  1. Set R1 = 1MΩ for IB = 4.3µA (or R1 = 470kΩ for IB = 10µA).\n'
              '  2. Vary Vcc (V2) from 0V to 10V in steps of 1V.\n'
              '  3. Record IC and VCE.\n'
              '• Operating Regions:\n'
              '  - Saturation Region (VCE < 0.2V): IC rises sharply.\n'
              '  - Active Region (VCE > 0.2V): IC remains almost constant (IC ≈ β · IB).\n'
              '  - Cutoff Region (IB = 0): IC ≈ 0.',
              style: TextStyle(height: 1.4, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 14),

          // 5. Types of BJT (Transistor Packages & Pinouts Visualizer)
          Card(
            elevation: isDark ? 1 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.tealAccent.withValues(alpha: 0.5) : Colors.teal,
                width: 1.5,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHigh
                    : Colors.teal.shade50.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.teal.shade700 : Colors.teal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.memory, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5. Types of BJT (Transistor Packages & Pinouts)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.tealAccent : const Color(0xFF004D40),
                              ),
                            ),
                            Text(
                              'Interactive 2D Technical Pinout & Package Visualizer',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.tealAccent.withValues(alpha: 0.8) : Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    'Explore technical 2D diagrams of BJT packages and internal semiconductor structures:\n'
                    '• TO-92 Plastic Package (BC547 / 2N3904) Front & Pinout\n'
                    '• TO-18 / TO-39 Metal Can Package (BC107) with Indexing Tab\n'
                    '• TO-220 Power Transistor Package (TIP31) with Heatsink Tab\n'
                    '• Internal NPN & PNP Silicon Crystal Junction Layers & IEEE Symbols\n\n'
                    'Inspect front physical views, bottom PCB footprints, and terminal lead definitions.',
                    style: TextStyle(height: 1.4, fontSize: 12.5, color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.memory, size: 20),
                      label: const Text('View Transistor Packages & Pinouts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.teal.shade700 : Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Bjt3dViewerScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required Color accentColor,
    required IconData icon,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? cs.surfaceContainer
        : accentColor.withValues(alpha: 0.08);

    final borderColor = isDark
        ? accentColor.withValues(alpha: 0.3)
        : accentColor.withValues(alpha: 0.25);

    final titleColor = isDark
        ? Color.lerp(accentColor, Colors.white, 0.25)!
        : accentColor;

    return Card(
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: titleColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                ),
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
