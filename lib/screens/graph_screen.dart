import 'package:flutter/material.dart';
import '../models/experiment_session.dart';
import '../models/input_reading.dart';
import '../models/output_reading.dart';
import '../services/experiment_service.dart';
import '../widgets/graph_widget.dart';

/// Screen for plotting BJT Input & Output characteristic curves.
/// (Module assigned to Ishan).
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  int _tabIndex = 0; // 0: Input (IB vs VBE), 1: Output (IC vs VCE)
  bool _isLoading = false;
  ExperimentSession? _latestSession;

  // In-memory fallback sample points if no cloud session loaded yet
  List<InputReading> _inputReadings = [];
  List<OutputReading> _outputReadings = [];

  @override
  void initState() {
    super.initState();
    _fetchFromNeonCloud();
  }

  Future<void> _fetchFromNeonCloud() async {
    setState(() => _isLoading = true);
    try {
      final session = await ExperimentService.getLatestSession();
      if (session != null && mounted) {
        setState(() {
          _latestSession = session;
          if (session.inputReadings.isNotEmpty) _inputReadings = session.inputReadings;
          if (session.outputReadings.isNotEmpty) _outputReadings = session.outputReadings;
        });
      }
    } catch (e) {
      // Offline fallback
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
      CurveSeries(name: 'Vce = 1.0 V', color: Colors.cyanAccent, points: vce1Points),
      CurveSeries(name: 'Vce = 2.0 V', color: Colors.greenAccent, points: vce2Points),
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
      CurveSeries(name: 'IB = 4.3 µA (1MΩ)', color: Colors.amberAccent, points: ib43Points),
      CurveSeries(name: 'IB = 10.0 µA (470kΩ)', color: Colors.purpleAccent, points: ib10Points),
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
            tooltip: 'Refresh from Neon DB',
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            onPressed: _isLoading ? null : _fetchFromNeonCloud,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.stacked_line_chart),
                  label: Text('Input Curve (IB vs VBE)'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.ssid_chart),
                  label: Text('Output Curves (IC vs VCE)'),
                ),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (set) => setState(() => _tabIndex = set.first),
            ),
            const SizedBox(height: 12),
            if (_latestSession != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Plotting latest Neon DB session: ${_latestSession!.sessionId.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _tabIndex == 0
                  ? BjtCurveChart(
                      title: 'INPUT CHARACTERISTICS (Silicon BC547)',
                      xLabel: 'Base-Emitter Voltage VBE',
                      yLabel: 'Base Current IB',
                      xUnit: 'V',
                      yUnit: 'µA',
                      seriesList: inputSeries,
                    )
                  : BjtCurveChart(
                      title: 'OUTPUT CHARACTERISTICS (Family of Curves)',
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
