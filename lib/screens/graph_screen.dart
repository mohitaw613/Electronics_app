import 'package:flutter/material.dart';
import '../widgets/graph_widget.dart';

/// Screen for plotting Input & Output Characteristics curves from stored readings.
/// (Module assigned to Ishan).
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT Characteristics Graphs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Input (IB vs VBE)')),
                ButtonSegment(value: 1, label: Text('Output (IC vs VCE)')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (set) => setState(() => _tabIndex = set.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tabIndex == 0
                  ? const ExperimentGraphWidget(
                      title: 'Input Characteristics (IB vs VBE)',
                      xLabel: 'VBE (Volts)',
                      yLabel: 'IB (µA)',
                    )
                  : const ExperimentGraphWidget(
                      title: 'Output Characteristics (IC vs VCE)',
                      xLabel: 'VCE (Volts)',
                      yLabel: 'IC (mA)',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
