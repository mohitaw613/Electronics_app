import 'package:flutter/material.dart';
import '../models/input_reading.dart';
import '../models/output_reading.dart';
import '../services/experiment_service.dart';
import '../widgets/graph_widget.dart';

/// Screen for plotting BJT Input & Output characteristic curves.
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  int _tabIndex = 0; // 0: Input (IB vs VBE), 1: Output (IC vs VCE)
  bool _isLoading = false;

  List<InputReading> get _inputReadings => ExperimentService.liveInputReadings;
  List<OutputReading> get _outputReadings => ExperimentService.liveOutputReadings;

  @override
  void initState() {
    super.initState();
    _fetchFromNeonCloud();
  }

  Future<void> _fetchFromNeonCloud() async {
    setState(() => _isLoading = true);
    try {
      await ExperimentService.getLatestSession();
      if (mounted) setState(() {});
    } catch (e) {
      // Offline fallback: live in-memory data remains intact
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CurveSeries> _buildInputSeries() {
    final vce1Points = _inputReadings
        .where((r) => r.vce == 1.0)
        .map((r) => PointData(r.vbe, r.ib))
        .toList();

    final vce2Points = _inputReadings
        .where((r) => r.vce == 2.0)
        .map((r) => PointData(r.vbe, r.ib))
        .toList();

    return [
      CurveSeries(name: 'Vce = 1.0 V', color: Colors.blueAccent, points: vce1Points),
      CurveSeries(name: 'Vce = 2.0 V', color: Colors.teal, points: vce2Points),
    ];
  }

  List<CurveSeries> _buildOutputSeries() {
    final ib43Points = _outputReadings
        .where((r) => (r.ib - 4.3).abs() < 0.1)
        .map((r) => PointData(r.vce, r.ic))
        .toList();

    final ib10Points = _outputReadings
        .where((r) => (r.ib - 10.0).abs() < 0.1)
        .map((r) => PointData(r.vce, r.ic))
        .toList();

    return [
      CurveSeries(name: 'IB = 4.3 µA (1MΩ)', color: Colors.deepOrange, points: ib43Points),
      CurveSeries(name: 'IB = 10.0 µA (470kΩ)', color: Colors.indigo, points: ib10Points),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final inputSeries = _buildInputSeries();
    final outputSeries = _buildOutputSeries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT Characteristics Curves'),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            onPressed: _isLoading ? null : _fetchFromNeonCloud,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Tab Selector without Overflow
            SegmentedButton<int>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.stacked_line_chart, size: 16),
                  label: Text('Input (IB - VBE)', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.ssid_chart, size: 16),
                  label: Text('Output (IC - VCE)', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (set) => setState(() => _tabIndex = set.first),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _tabIndex == 0
                  ? BjtCurveChart(
                      title: 'Input (Silicon BC547)',
                      xLabel: 'Base-Emitter Voltage VBE',
                      yLabel: 'Base Current IB',
                      xUnit: 'V',
                      yUnit: 'µA',
                      seriesList: inputSeries,
                    )
                  : BjtCurveChart(
                      title: 'Output (Family of Curves)',
                      xLabel: 'Collector-Emitter Voltage VCE',
                      yLabel: 'Collector Current IC',
                      xUnit: 'V',
                      yUnit: 'mA',
                      seriesList: outputSeries,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
