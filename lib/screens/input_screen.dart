import 'package:flutter/material.dart';
import '../models/input_reading.dart';

/// Screen for recording Input Characteristics (IB vs VBE at constant VCE).
/// (Module assigned to Dinesh).
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final List<InputReading> _readings = [];
  double _selectedVce = 1.0; // Fixed VCE: 1.0V or 2.0V

  final _vbbController = TextEditingController();
  final _vbeController = TextEditingController();
  final _ibController = TextEditingController();

  @override
  void dispose() {
    _vbbController.dispose();
    _vbeController.dispose();
    _ibController.dispose();
    super.dispose();
  }

  void _addReading() {
    final vbb = double.tryParse(_vbbController.text);
    final vbe = double.tryParse(_vbeController.text);
    final ib = double.tryParse(_ibController.text);

    if (vbb != null && vbe != null && ib != null) {
      setState(() {
        _readings.add(InputReading(
          vbb: vbb,
          vce: _selectedVce,
          vbe: vbe,
          ib: ib,
        ));
        _vbbController.clear();
        _vbeController.clear();
        _ibController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Characteristics (IB vs VBE)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('VCE = 1.0V')),
                ButtonSegment(value: 2.0, label: Text('VCE = 2.0V')),
              ],
              selected: {_selectedVce},
              onSelectionChanged: (set) => setState(() => _selectedVce = set.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vbbController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Vbb (V)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _vbeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Vbe (V)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ibController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'IB (µA)', isDense: true),
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
                        DataColumn(label: Text('Vbb (V)')),
                        DataColumn(label: Text('Vbe (V)')),
                        DataColumn(label: Text('IB (µA)')),
                      ],
                      rows: _readings
                          .where((r) => r.vce == _selectedVce)
                          .map((r) => DataRow(cells: [
                                DataCell(Text('${r.vbb}')),
                                DataCell(Text('${r.vbe}')),
                                DataCell(Text('${r.ib}')),
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
