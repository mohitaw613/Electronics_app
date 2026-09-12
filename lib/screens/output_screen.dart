import 'package:flutter/material.dart';
import '../models/output_reading.dart';

/// Screen for recording Output Characteristics (IC vs VCE at constant IB).
/// (Module assigned to Dinesh).
class OutputScreen extends StatefulWidget {
  const OutputScreen({super.key});

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  final List<OutputReading> _readings = [];
  double _selectedIb = 4.3; // Fixed IB: 4.3µA (R1=1MΩ) or 10.0µA (R1=470kΩ)

  final _vccController = TextEditingController();
  final _vceController = TextEditingController();
  final _icController = TextEditingController();

  @override
  void dispose() {
    _vccController.dispose();
    _vceController.dispose();
    _icController.dispose();
    super.dispose();
  }

  void _addReading() {
    final vcc = double.tryParse(_vccController.text);
    final vce = double.tryParse(_vceController.text);
    final ic = double.tryParse(_icController.text);

    if (vcc != null && vce != null && ic != null) {
      setState(() {
        _readings.add(OutputReading(
          vcc: vcc,
          ib: _selectedIb,
          vce: vce,
          ic: ic,
        ));
        _vccController.clear();
        _vceController.clear();
        _icController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Output Characteristics (IC vs VCE)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 4.3, label: Text('IB = 4.3µA (1MΩ)')),
                ButtonSegment(value: 10.0, label: Text('IB = 10µA (470kΩ)')),
              ],
              selected: {_selectedIb},
              onSelectionChanged: (set) => setState(() => _selectedIb = set.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vccController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Vcc (V)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _vceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Vce (V)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _icController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'IC (mA)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addReading,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _readings.isEmpty
                  ? const Center(child: Text('No readings recorded yet.'))
                  : DataTable(
                      columns: const [
                        DataColumn(label: Text('Vcc (V)')),
                        DataColumn(label: Text('Vce (V)')),
                        DataColumn(label: Text('IC (mA)')),
                      ],
                      rows: _readings
                          .where((r) => r.ib == _selectedIb)
                          .map((r) => DataRow(cells: [
                                DataCell(Text('${r.vcc}')),
                                DataCell(Text('${r.vce}')),
                                DataCell(Text('${r.ic}')),
                              ]))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
