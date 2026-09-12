import 'package:flutter/material.dart';
import '../models/output_reading.dart';
import '../services/experiment_service.dart';
import 'graph_screen.dart';

/// Screen for recording Output Characteristics (IC vs VCE at constant IB).
/// (Module assigned to Dinesh).
class OutputScreen extends StatefulWidget {
  const OutputScreen({super.key});

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  final List<OutputReading> _readings = [];
  double _selectedIb = 4.3; // Fixed IB: 4.3µA (1MΩ) or 10.0µA (470kΩ)
  bool _isSaving = false;

  final _vccController = TextEditingController();
  final _vceController = TextEditingController();
  final _icController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialSampleSteps();
  }

  @override
  void dispose() {
    _vccController.dispose();
    _vceController.dispose();
    _icController.dispose();
    super.dispose();
  }

  /// Pre-populates standard Vcc steps from manual Page 18
  void _loadInitialSampleSteps() {
    final standardVcc = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];

    // For IB = 4.3µA (Beta ~150 => Saturation ~0.65mA)
    for (final vcc in standardVcc) {
      double vce = vcc * 0.9;
      double ic = 0.65; // ~0.65mA
      if (vcc <= 1.0) {
        vce = vcc * 0.2;
        ic = vcc * 0.6;
      }
      _readings.add(OutputReading(
        vcc: vcc,
        ib: 4.3,
        vce: double.parse(vce.toStringAsFixed(2)),
        ic: double.parse(ic.toStringAsFixed(2)),
      ));
    }

    // For IB = 10.0µA (Beta ~150 => Active ~1.50mA)
    for (final vcc in standardVcc) {
      double vce = vcc * 0.85;
      double ic = 1.50; // ~1.5mA
      if (vcc <= 1.0) {
        vce = vcc * 0.25;
        ic = vcc * 1.4;
      }
      _readings.add(OutputReading(
        vcc: vcc,
        ib: 10.0,
        vce: double.parse(vce.toStringAsFixed(2)),
        ic: double.parse(ic.toStringAsFixed(2)),
      ));
    }
  }

  void _addCustomReading() {
    final vcc = double.tryParse(_vccController.text);
    final vce = double.tryParse(_vceController.text);
    final ic = double.tryParse(_icController.text);

    if (vcc != null && vce != null && ic != null) {
      setState(() {
        _readings.removeWhere((r) => (r.ib - _selectedIb).abs() < 0.1 && (r.vcc - vcc).abs() < 0.01);
        _readings.add(OutputReading(
          vcc: vcc,
          ib: _selectedIb,
          vce: vce,
          ic: ic,
        ));
        _readings.sort((a, b) => a.vcc.compareTo(b.vcc));
        _vccController.clear();
        _vceController.clear();
        _icController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reading saved for Vcc = $vcc V (IB = $_selectedIb µA)')),
      );
    }
  }

  Future<void> _saveToCloud() async {
    setState(() => _isSaving = true);
    try {
      await ExperimentService.saveExperimentSession(outputReadings: _readings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Output readings saved to Neon PostgreSQL!'),
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
    final filteredReadings = _readings.where((r) => (r.ib - _selectedIb).abs() < 0.1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Output Characteristics (IC vs VCE)'),
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
              color: Colors.teal.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Manual Reading Entry: Measure Vce (Volts) and IC (mA) across Vcc (0V to 10V) while holding base current IB constant at 4.3µA or 10.0µA.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 4.3, label: Text('IB = 4.3 µA (R1 = 1MΩ)')),
                ButtonSegment(value: 10.0, label: Text('IB = 10.0 µA (R1 = 470kΩ)')),
              ],
              selected: {_selectedIb},
              onSelectionChanged: (set) => setState(() => _selectedIb = set.first),
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
                            controller: _vccController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Vcc (V)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _vceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Vce (V)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _icController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'IC (mA)', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCustomReading,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Observation Table (IB = $_selectedIb µA)',
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
                  DataColumn(label: Text('Vcc Supply (V)')),
                  DataColumn(label: Text('Vce Measured (V)')),
                  DataColumn(label: Text('IC Current (mA)')),
                  DataColumn(label: Text('Action')),
                ],
                rows: filteredReadings.map((r) {
                  return DataRow(cells: [
                    DataCell(Text('${r.vcc} V')),
                    DataCell(Text('${r.vce} V')),
                    DataCell(Text('${r.ic} mA')),
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
