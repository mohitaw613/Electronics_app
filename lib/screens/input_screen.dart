import 'package:flutter/material.dart';
import '../models/input_reading.dart';
import '../services/experiment_service.dart';
import 'graph_screen.dart';

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
  bool _isSaving = false;

  final _vbbController = TextEditingController();
  final _vbeController = TextEditingController();
  final _ibController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialSampleSteps();
  }

  @override
  void dispose() {
    _vbbController.dispose();
    _vbeController.dispose();
    _ibController.dispose();
    super.dispose();
  }

  /// Pre-populates the standard Vbb steps from manual Page 17
  void _loadInitialSampleSteps() {
    final standardVbb = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    for (final vbb in standardVbb) {
      // Calculate realistic default base conduction for BC547 silicon
      double vbe = 0.0;
      double ib = 0.0;
      if (vbb > 0.6) {
        vbe = 0.65 + (vbb / 5.0) * 0.07; // ~0.65V - 0.72V
        ib = (vbb - vbe) / 1.0 * 1000.0; // In µA with 1kΩ Rb
      }
      _readings.add(InputReading(vbb: vbb, vce: 1.0, vbe: double.parse(vbe.toStringAsFixed(3)), ib: double.parse(ib.toStringAsFixed(1))));
      _readings.add(InputReading(vbb: vbb, vce: 2.0, vbe: double.parse(vbe.toStringAsFixed(3)), ib: double.parse((ib * 0.98).toStringAsFixed(1))));
    }
  }

  void _addCustomReading() {
    final vbb = double.tryParse(_vbbController.text);
    final vbe = double.tryParse(_vbeController.text);
    final ib = double.tryParse(_ibController.text);

    if (vbb != null && vbe != null && ib != null) {
      setState(() {
        _readings.removeWhere((r) => r.vce == _selectedVce && (r.vbb - vbb).abs() < 0.01);
        _readings.add(InputReading(
          vbb: vbb,
          vce: _selectedVce,
          vbe: vbe,
          ib: ib,
        ));
        _readings.sort((a, b) => a.vbb.compareTo(b.vbb));
        _vbbController.clear();
        _vbeController.clear();
        _ibController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reading saved for Vbb = ${vbb}V (Vce = ${_selectedVce}V)')),
      );
    }
  }

  Future<void> _saveToCloud() async {
    setState(() => _isSaving = true);
    try {
      await ExperimentService.saveExperimentSession(inputReadings: _readings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Input readings saved to Neon PostgreSQL!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReadings = _readings.where((r) => r.vce == _selectedVce).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Characteristics (IB vs VBE)'),
        actions: [
          IconButton(
            tooltip: 'View Graph',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GraphScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Manual Reading Entry: Measure Vbe (Volts) and IB (µA) across V1 (0V to 5V) while holding Vce constant at 1V or 2V.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('VCE = 1.0 V')),
                ButtonSegment(value: 2.0, label: Text('VCE = 2.0 V')),
              ],
              selected: {_selectedVce},
              onSelectionChanged: (set) => setState(() => _selectedVce = set.first),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add / Update Reading Row', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _vbbController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Vbb (V)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _vbeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Vbe (V)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ibController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'IB (µA)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addCustomReading,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Row'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Observation Table (Vce = ${_selectedVce}V)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload, size: 16),
                  label: const Text('Save to Neon DB'),
                  onPressed: _isSaving ? null : _saveToCloud,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                columns: const [
                  DataColumn(label: Text('Vbb Supply (V)')),
                  DataColumn(label: Text('Vbe Measured (V)')),
                  DataColumn(label: Text('IB Current (µA)')),
                  DataColumn(label: Text('Action')),
                ],
                rows: filteredReadings.map((r) {
                  return DataRow(cells: [
                    DataCell(Text('${r.vbb} V')),
                    DataCell(Text('${r.vbe} V')),
                    DataCell(Text('${r.ib} µA')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _readings.remove(r)),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
