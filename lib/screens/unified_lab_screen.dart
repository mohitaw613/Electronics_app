import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/input_reading.dart';
import '../models/output_reading.dart';
import '../models/slope_measurement.dart';
import '../services/experiment_service.dart';
import '../widgets/graph_widget.dart';
import '../widgets/prelab_calculator_card.dart';
import '../widgets/proteus_bjt_circuit.dart';
import '../widgets/slope_chart_widget.dart';
import '../widgets/virtual_breadboard.dart';
import 'bjt_2d_viewer_screen.dart';
import 'mcq_screen.dart';
import 'notebook_view_screen.dart';

// ── Transistor Model ──────────────────────────────────────────────────────────
class TransistorSpec {
  final String name;
  final String type; // 'NPN' or 'PNP'
  final double beta;
  final double vbeForward; // typical V_BE in forward active
  final double maxIcMa;
  final double maxVceo;
  final String package;
  final String description;

  const TransistorSpec({
    required this.name,
    required this.type,
    required this.beta,
    required this.vbeForward,
    required this.maxIcMa,
    required this.maxVceo,
    required this.package,
    required this.description,
  });
}

const List<TransistorSpec> kTransistors = [
  TransistorSpec(name: 'BC547', type: 'NPN', beta: 150, vbeForward: 0.65, maxIcMa: 100, maxVceo: 45, package: 'TO-92', description: 'General purpose NPN (default lab transistor)'),
  TransistorSpec(name: 'BC548', type: 'NPN', beta: 200, vbeForward: 0.65, maxIcMa: 100, maxVceo: 30, package: 'TO-92', description: 'High-gain NPN, lower noise'),
  TransistorSpec(name: 'BC549', type: 'NPN', beta: 220, vbeForward: 0.65, maxIcMa: 100, maxVceo: 30, package: 'TO-92', description: 'Low-noise NPN for audio'),
  TransistorSpec(name: '2N2222', type: 'NPN', beta: 100, vbeForward: 0.70, maxIcMa: 600, maxVceo: 40, package: 'TO-18/TO-92', description: 'Robust NPN switching transistor'),
  TransistorSpec(name: '2N3904', type: 'NPN', beta: 100, vbeForward: 0.70, maxIcMa: 200, maxVceo: 40, package: 'TO-92', description: 'Common NPN small-signal transistor'),
  TransistorSpec(name: 'BC557', type: 'PNP', beta: 150, vbeForward: 0.65, maxIcMa: 100, maxVceo: 45, package: 'TO-92', description: 'PNP complement of BC547'),
  TransistorSpec(name: 'BC558', type: 'PNP', beta: 200, vbeForward: 0.65, maxIcMa: 100, maxVceo: 30, package: 'TO-92', description: 'PNP complement of BC548'),
  TransistorSpec(name: '2N3906', type: 'PNP', beta: 100, vbeForward: 0.70, maxIcMa: 200, maxVceo: 40, package: 'TO-92', description: 'PNP complement of 2N3904'),
];

// ─────────────────────────────────────────────────────────────────────────────

class UnifiedLabScreen extends StatefulWidget {
  const UnifiedLabScreen({super.key});

  @override
  State<UnifiedLabScreen> createState() => _UnifiedLabScreenState();
}

class _UnifiedLabScreenState extends State<UnifiedLabScreen> {
  // Whole-app zoom factor (default 85%) and zoom option toggle
  double _appZoom = 0.85;
  bool _enableAppZoom = false;

  // Selected transistor (defaults to BC547, the standard lab transistor)
  TransistorSpec _selectedTransistor = kTransistors[0];

  // Simulation controls
  double _vbb = 2.5;
  double _vcc = 10.0;
  double _rb = 100.0;
  double _rc = 1.0;

  // Physics calculations (Always reliable, rock-solid BJT CE model)
  // Uses selected transistor's V_BE forward voltage and β
  double get _vbe {
    final vf = _selectedTransistor.vbeForward;
    if (_vbb <= (vf - 0.05)) return _vbb;
    return vf + math.min(0.08, (_vbb - (vf - 0.05)) * 0.02);
  }

  double get _ib {
    if (_vbb <= _vbe) return 0.0;
    return ((_vbb - _vbe) / (_rb * 1000.0)) * 1000000.0; // in uA
  }

  double get _ic {
    final beta = _selectedTransistor.beta;
    final activeIc = (_ib * beta) / 1000.0; // in mA
    final satLimit = (_vcc / (_rc * 1000.0)) * 1000.0; // in mA
    return math.min(activeIc, satLimit);
  }

  double get _vce {
    final vDrop = (_ic / 1000.0) * (_rc * 1000.0);
    return math.max(0.15, _vcc - vDrop);
  }

  String get _operatingRegion {
    if (_ib <= 0.01) return 'CUTOFF (Transistor OFF)';
    if (_vce <= 0.25) return 'SATURATION (Fully ON)';
    return 'ACTIVE (Linear Amplification)';
  }

  Color get _regionColor {
    if (_ib <= 0.01) return Colors.redAccent;
    if (_vce <= 0.25) return Colors.orangeAccent;
    return Colors.green;
  }

  // Data entry
  int _dataTab = 0; // 0: input, 1: output
  double _fixedVce = 1.0;
  double _fixedIb = 4.3;

  List<TextEditingController> _inC1 = [], _inC2 = [], _inC3 = [];
  List<TextEditingController> _outC1 = [], _outC2 = [], _outC3 = [];
  List<FocusNode> _inF1 = [], _inF2 = [], _inF3 = [];
  List<FocusNode> _outF1 = [], _outF2 = [], _outF3 = [];

  // Graph tab
  int _graphTab = 0; // 0: input, 1: output

  // Notion-Style Section Collapse & Navigation State
  bool _expandTheory = false;     // Collapsed by default
  bool _expandCircuit = true;    // Expanded - Wire connection circuit
  bool _expandSimulation = true; // Expanded - Live simulation & controls
  bool _expandTables = true;     // Expanded
  bool _expandGraphs = true;     // Expanded
  bool _expandNotes = false;     // Collapsed by default
  bool _expandMcq = true;        // Expanded - MCQs
  bool _expandReport = true;     // Expanded - Lab Record Report
  bool _expandIndustrial = true; // Expanded - Industrial Benefits

  // Section Keys for smooth auto-scrolling
  final GlobalKey _keyTheory = GlobalKey();
  final GlobalKey _keyCircuit = GlobalKey();
  final GlobalKey _keySimulation = GlobalKey();
  final GlobalKey _keyTables = GlobalKey();
  final GlobalKey _keyGraphs = GlobalKey();
  final GlobalKey _keyNotes = GlobalKey();
  final GlobalKey _keyMcq = GlobalKey();
  final GlobalKey _keyReport = GlobalKey();
  final GlobalKey _keyIndustrial = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  void _scrollToSection(GlobalKey key, int sectionIdx) {
    setState(() {
      if (sectionIdx == 0) _expandTheory = true;
      if (sectionIdx == 1) _expandCircuit = true;
      if (sectionIdx == 2) _expandSimulation = true;
      if (sectionIdx == 3) _expandTables = true;
      if (sectionIdx == 4) _expandGraphs = true;
      if (sectionIdx == 5) _expandNotes = true;
      if (sectionIdx == 6) _expandMcq = true;
      if (sectionIdx == 7) _expandReport = true;
      if (sectionIdx == 8) _expandIndustrial = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _soloSection(int sectionIdx, GlobalKey key) {
    setState(() {
      _expandTheory = (sectionIdx == 0);
      _expandCircuit = (sectionIdx == 1);
      _expandSimulation = (sectionIdx == 2);
      _expandTables = (sectionIdx == 3);
      _expandGraphs = (sectionIdx == 4);
      _expandNotes = (sectionIdx == 5);
      _expandMcq = (sectionIdx == 6);
      _expandReport = (sectionIdx == 7);
      _expandIndustrial = (sectionIdx == 8);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleAllSections(bool expand) {
    setState(() {
      _expandTheory = expand;
      _expandCircuit = expand;
      _expandSimulation = expand;
      _expandTables = expand;
      _expandGraphs = expand;
      _expandNotes = expand;
      _expandMcq = expand;
      _expandReport = expand;
      _expandIndustrial = expand;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllersAndFocus();
    super.dispose();
  }

  void _disposeControllersAndFocus() {
    for (var c in [..._inC1, ..._inC2, ..._inC3, ..._outC1, ..._outC2, ..._outC3]) {
      c.dispose();
    }
    for (var f in [..._inF1, ..._inF2, ..._inF3, ..._outF1, ..._outF2, ..._outF3]) {
      f.dispose();
    }
    _inC1 = []; _inC2 = []; _inC3 = [];
    _outC1 = []; _outC2 = []; _outC3 = [];
    _inF1 = []; _inF2 = []; _inF3 = [];
    _outF1 = []; _outF2 = []; _outF3 = [];
  }

  void _loadDefaults() {
    _disposeControllersAndFocus();

    final vf = _selectedTransistor.vbeForward;
    final beta = _selectedTransistor.beta;

    final inputs = <InputReading>[];
    for (final vbb in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]) {
      double vbe = 0.0, ib = 0.0;
      if (vbb > (vf - 0.05)) {
        vbe = vf + (vbb / 5.0) * 0.07;
        ib = ((vbb - vbe) / 100.0) * 1000.0; // Rb = 100k, Ib in uA
      }
      inputs.add(InputReading(vbb: vbb, vce: 1.0, vbe: double.parse(vbe.toStringAsFixed(3)), ib: double.parse(ib.toStringAsFixed(1))));
      inputs.add(InputReading(vbb: vbb, vce: 2.0, vbe: double.parse(vbe.toStringAsFixed(3)), ib: double.parse((ib * 0.96).toStringAsFixed(1))));
    }
    ExperimentService.liveInputReadings = inputs;

    final outputs = <OutputReading>[];
    // Saturation level is proportional to transistor beta (relative to default beta=150)
    final betaRatio = beta / 150.0;
    for (final vcc in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]) {
      double vce = vcc * 0.9;
      double ic43 = (4.3 * beta / 1000.0); // active Ic = Ib * beta
      if (vcc <= 1.0) { vce = vcc * 0.2; ic43 = vcc * 0.6 * betaRatio; }
      outputs.add(OutputReading(vcc: vcc, ib: 4.3, vce: double.parse(vce.toStringAsFixed(3)), ic: double.parse(ic43.toStringAsFixed(3))));

      double ic10 = (10.0 * beta / 1000.0);
      if (vcc <= 1.0) { ic10 = vcc * 1.4 * betaRatio; }
      outputs.add(OutputReading(vcc: vcc, ib: 10.0, vce: double.parse(vce.toStringAsFixed(3)), ic: double.parse(ic10.toStringAsFixed(3))));
    }
    ExperimentService.liveOutputReadings = outputs;

    _rebuildControllers();
  }

  void _rebuildControllers() {
    _disposeControllersAndFocus();
    for (final r in ExperimentService.liveInputReadings.where((r) => (r.vce - _fixedVce).abs() < 0.1)) {
      _inC1.add(TextEditingController(text: r.vbb.toStringAsFixed(1)));
      _inC2.add(TextEditingController(text: r.vbe.toStringAsFixed(3)));
      _inC3.add(TextEditingController(text: r.ib.toStringAsFixed(1)));
      _inF1.add(FocusNode());
      _inF2.add(FocusNode());
      _inF3.add(FocusNode());
    }
    for (final r in ExperimentService.liveOutputReadings.where((r) => (r.ib - _fixedIb).abs() < 0.5)) {
      _outC1.add(TextEditingController(text: r.vcc.toStringAsFixed(1)));
      _outC2.add(TextEditingController(text: r.vce.toStringAsFixed(3)));
      _outC3.add(TextEditingController(text: r.ic.toStringAsFixed(3)));
      _outF1.add(FocusNode());
      _outF2.add(FocusNode());
      _outF3.add(FocusNode());
    }
    setState(() {});
  }

  void _syncInput() {
    final updated = <InputReading>[];
    final otherVce = _fixedVce == 1.0 ? 2.0 : 1.0;
    updated.addAll(ExperimentService.liveInputReadings.where((r) => (r.vce - otherVce).abs() < 0.1));
    for (int i = 0; i < _inC1.length; i++) {
      final a = double.tryParse(_inC1[i].text), b = double.tryParse(_inC2[i].text), c = double.tryParse(_inC3[i].text);
      if (a != null && b != null && c != null) updated.add(InputReading(vbb: a, vce: _fixedVce, vbe: b, ib: c));
    }
    ExperimentService.liveInputReadings = updated;
    setState(() {});
  }

  void _syncOutput() {
    final updated = <OutputReading>[];
    final otherIb = (_fixedIb - 4.3).abs() < 0.5 ? 10.0 : 4.3;
    updated.addAll(ExperimentService.liveOutputReadings.where((r) => (r.ib - otherIb).abs() > 0.5));
    for (int i = 0; i < _outC1.length; i++) {
      final a = double.tryParse(_outC1[i].text), b = double.tryParse(_outC2[i].text), c = double.tryParse(_outC3[i].text);
      if (a != null && b != null && c != null) updated.add(OutputReading(vcc: a, ib: _fixedIb, vce: b, ic: c));
    }
    ExperimentService.liveOutputReadings = updated;
    setState(() {});
  }

  void _addRow() {
    setState(() {
      if (_dataTab == 0) {
        _inC1.add(TextEditingController());
        _inC2.add(TextEditingController());
        _inC3.add(TextEditingController());
        _inF1.add(FocusNode());
        _inF2.add(FocusNode());
        _inF3.add(FocusNode());
      } else {
        _outC1.add(TextEditingController());
        _outC2.add(TextEditingController());
        _outC3.add(TextEditingController());
        _outF1.add(FocusNode());
        _outF2.add(FocusNode());
        _outF3.add(FocusNode());
      }
    });
  }

  void _removeRow(int i) {
    setState(() {
      if (_dataTab == 0 && i < _inC1.length) {
        _inC1[i].dispose(); _inC2[i].dispose(); _inC3[i].dispose();
        _inF1[i].dispose(); _inF2[i].dispose(); _inF3[i].dispose();
        _inC1.removeAt(i); _inC2.removeAt(i); _inC3.removeAt(i);
        _inF1.removeAt(i); _inF2.removeAt(i); _inF3.removeAt(i);
        _syncInput();
      } else if (_dataTab == 1 && i < _outC1.length) {
        _outC1[i].dispose(); _outC2[i].dispose(); _outC3[i].dispose();
        _outF1[i].dispose(); _outF2[i].dispose(); _outF3[i].dispose();
        _outC1.removeAt(i); _outC2.removeAt(i); _outC3.removeAt(i);
        _outF1.removeAt(i); _outF2.removeAt(i); _outF3.removeAt(i);
        _syncOutput();
      }
    });
  }

  /// Automatically navigate focus to the right cell, or to the next line when reaching the end of the row
  void _moveToNextCell(int row, int col) {
    final focusNodes = _dataTab == 0 ? [_inF1, _inF2, _inF3] : [_outF1, _outF2, _outF3];
    final count = focusNodes[0].length;

    if (col < 2) {
      // Direct focus to the right cell in the same row
      focusNodes[col + 1][row].requestFocus();
    } else {
      // Reached maximum column of current row -> advance to next row, column 0
      if (row + 1 < count) {
        focusNodes[0][row + 1].requestFocus();
      } else {
        // Last row reached -> automatically create next row and focus on its first cell
        _addRow();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final updated = _dataTab == 0 ? [_inF1, _inF2, _inF3] : [_outF1, _outF2, _outF3];
          if (row + 1 < updated[0].length) {
            updated[0][row + 1].requestFocus();
          }
        });
      }
    }
  }

  List<CurveSeries> _inputSeries() {
    final s1 = ExperimentService.liveInputReadings.where((r) => (r.vce - 1.0).abs() < 0.1).map((r) => PointData(r.vbe, r.ib)).toList();
    final s2 = ExperimentService.liveInputReadings.where((r) => (r.vce - 2.0).abs() < 0.1).map((r) => PointData(r.vbe, r.ib)).toList();
    return [
      CurveSeries(name: 'Vce=1V', color: Colors.blueAccent, points: s1),
      CurveSeries(name: 'Vce=2V', color: Colors.teal, points: s2),
    ];
  }

  List<CurveSeries> _outputSeries() {
    final s1 = ExperimentService.liveOutputReadings.where((r) => (r.ib - 4.3).abs() < 0.5).map((r) => PointData(r.vce, r.ic)).toList();
    final s2 = ExperimentService.liveOutputReadings.where((r) => (r.ib - 10.0).abs() < 0.5).map((r) => PointData(r.vce, r.ic)).toList();
    return [
      CurveSeries(name: 'Ib=4.3µA', color: Colors.deepOrange, points: s1),
      CurveSeries(name: 'Ib=10µA', color: Colors.indigo, points: s2),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJT CE Lab', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        titleSpacing: 10,
        backgroundColor: cs.inversePrimary,
        actions: [
          // App-Wide Zoom Option (Default 85%, Toggleable ON/OFF)
          if (!_enableAppZoom)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _enableAppZoom = true),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 14, color: cs.primary),
                    const SizedBox(width: 3),
                    Text(
                      'Zoom: OFF (85%)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.purple.shade400, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _appZoom > 0.72 ? () => setState(() => _appZoom = math.max(0.70, _appZoom - 0.15)) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.remove, size: 14, color: _appZoom > 0.72 ? cs.onSurface : Colors.grey),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _appZoom = 0.85),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '${(_appZoom * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _appZoom < 1.78 ? () => setState(() => _appZoom = math.min(1.8, _appZoom + 0.15)) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.add, size: 14, color: _appZoom < 1.78 ? cs.onSurface : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => setState(() {
                      _enableAppZoom = false;
                      _appZoom = 0.85;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Lock', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ),
                  ),
                ],
              ),
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeNotifier,
            builder: (context, mode, _) => IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => appThemeNotifier.value = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.memory),
            tooltip: '2D Pinouts',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Bjt3dViewerScreen())),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            icon: const Icon(Icons.auto_stories),
            tooltip: 'Lab Record Report',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotebookViewScreen())),
          ),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_appZoom),
        ),
        child: Column(
          children: [
            // Pinned Notion-style Quick Navigation Bar
            _quickNavBar(cs, isDark),
            // Main content with InteractiveViewer and Notion Collapsible Sections
            Expanded(
              child: InteractiveViewer(
                minScale: 0.7,
                maxScale: 1.8,
                scaleEnabled: _enableAppZoom,
                panEnabled: _enableAppZoom,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
                  children: [
                    // ========== 1. THEORY ==========
                    _notionHeading(
                      key: _keyTheory,
                      num: '1',
                      title: 'Theory & Background',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      isExpanded: _expandTheory,
                      onToggle: () => setState(() => _expandTheory = !_expandTheory),
                      onSolo: () => _soloSection(0, _keyTheory),
                    ),
                    if (_expandTheory) _theoryCard(cs),

                    // ========== 2. CIRCUIT WIRING ==========
                    _notionHeading(
                      key: _keyCircuit,
                      num: '2',
                      title: 'Circuit',
                      icon: Icons.cable,
                      color: Colors.orange,
                      isExpanded: _expandCircuit,
                      onToggle: () => setState(() => _expandCircuit = !_expandCircuit),
                      onSolo: () => _soloSection(1, _keyCircuit),
                    ),
                    if (_expandCircuit) ...[
                      const VirtualBreadboardWidget(),
                      const SizedBox(height: 10),
                    ],

                    // ========== 3. SIMULATION ==========
                    _notionHeading(
                      key: _keySimulation,
                      num: '3',
                      title: 'Simulation',
                      icon: Icons.precision_manufacturing,
                      color: Colors.deepOrange,
                      isExpanded: _expandSimulation,
                      onToggle: () => setState(() => _expandSimulation = !_expandSimulation),
                      onSolo: () => _soloSection(2, _keySimulation),
                    ),
                    if (_expandSimulation) ...[
                      // Transistor Selection Card
                      _transistorSelectorCard(cs),
                      const SizedBox(height: 8),

                      // Always reliable Proteus Circuit CAD Schematic
                      ProteusBjtCircuit(
                        vbb: _vbb,
                        vcc: _vcc,
                        rb: _rb,
                        rc: _rc,
                        vbe: _vbe,
                        vce: _vce,
                        ib: _ib,
                        ic: _ic,
                        region: _operatingRegion,
                        transistorName: _selectedTransistor.name,
                        transistorType: _selectedTransistor.type,
                      ),
                      const SizedBox(height: 10),

                      // Operating Region Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _regionColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _regionColor, width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, color: _regionColor, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _operatingRegion,
                                style: TextStyle(color: _regionColor, fontWeight: FontWeight.bold, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Digital Meters
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _meter('Vʙᴇ (V)', '${_vbe.toStringAsFixed(3)} V', Colors.blue),
                              _meter('Iʙ (µA)', '${_ib.toStringAsFixed(1)} µA', Colors.indigo),
                              _meter('Vᴄᴇ (V)', '${_vce.toStringAsFixed(2)} V', Colors.deepOrange),
                              _meter('Iᴄ (mA)', '${_ic.toStringAsFixed(2)} mA', Colors.teal),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sliders Controls
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Simulation Scrollers (Controls)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(height: 6),
                              _slider('Base Supply (V₁ / Vᵦᵦ)', _vbb, 0, 5, 'V', (v) => setState(() => _vbb = v)),
                              _slider('Collector Supply (V₂ / Vᴄᴄ)', _vcc, 0, 15, 'V', (v) => setState(() => _vcc = v)),
                              _slider('Base Resistor (R₁ / Rᵦ)', _rb, 10, 1000, 'kΩ', (v) => setState(() => _rb = v)),
                              _slider('Collector Resistor (R₂ / Rᴄ)', _rc, 0.5, 5, 'kΩ', (v) => setState(() => _rc = v)),
                            ],
                          ),
                        ),
                      ),

                      // ========== PRE-LAB CALC ==========
                      const SizedBox(height: 8),
                      PreLabCalculatorCard(liveMeasuredVce: _vce, liveMeasuredIc: _ic),
                    ],

                    // ========== 4. DATA ENTRY ==========
                    _notionHeading(
                      key: _keyTables,
                      num: '4',
                      title: 'Observation Tables',
                      icon: Icons.table_chart,
                      color: Colors.teal,
                      isExpanded: _expandTables,
                      onToggle: () => setState(() => _expandTables = !_expandTables),
                      onSolo: () => _soloSection(3, _keyTables),
                    ),
                    if (_expandTables) ...[
                      // Tab buttons
                      Row(
                        children: [
                          Expanded(child: _tabBtn('Input Table', _dataTab == 0, () { setState(() { _dataTab = 0; }); _rebuildControllers(); })),
                          const SizedBox(width: 8),
                          Expanded(child: _tabBtn('Output Table', _dataTab == 1, () { setState(() { _dataTab = 1; }); _rebuildControllers(); })),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Filter Parameter Card
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dataTab == 0 ? 'Fixed Vᴄᴇ Parameter:' : 'Fixed Iʙ Parameter:',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              if (_dataTab == 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChoiceChip(label: const Text('1V', style: TextStyle(fontSize: 11)), selected: _fixedVce == 1.0, onSelected: (_) { setState(() => _fixedVce = 1.0); _rebuildControllers(); }),
                                    const SizedBox(width: 6),
                                    ChoiceChip(label: const Text('2V', style: TextStyle(fontSize: 11)), selected: _fixedVce == 2.0, onSelected: (_) { setState(() => _fixedVce = 2.0); _rebuildControllers(); }),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChoiceChip(label: const Text('4.3µA', style: TextStyle(fontSize: 11)), selected: _fixedIb == 4.3, onSelected: (_) { setState(() => _fixedIb = 4.3); _rebuildControllers(); }),
                                    const SizedBox(width: 6),
                                    ChoiceChip(label: const Text('10µA', style: TextStyle(fontSize: 11)), selected: _fixedIb == 10.0, onSelected: (_) { setState(() => _fixedIb = 10.0); _rebuildControllers(); }),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Table
                      _dataTable(cs),
                      const SizedBox(height: 6),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Add Row', style: TextStyle(fontSize: 12)), onPressed: _addRow),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(icon: const Icon(Icons.restore, size: 16), label: const Text('Auto-fill PDF Defaults', style: TextStyle(fontSize: 12)), onPressed: () { _loadDefaults(); }),
                        ],
                      ),
                    ],

                    // ========== 5. GRAPHS ==========
                    _notionHeading(
                      key: _keyGraphs,
                      num: '5',
                      title: 'Characteristic Curves',
                      icon: Icons.show_chart,
                      color: Colors.purple,
                      isExpanded: _expandGraphs,
                      onToggle: () => setState(() => _expandGraphs = !_expandGraphs),
                      onSolo: () => _soloSection(4, _keyGraphs),
                    ),
                    if (_expandGraphs) ...[
                      Row(
                        children: [
                          Expanded(child: _tabBtn('Input Curves (IB vs VBE)', _graphTab == 0, () => setState(() => _graphTab = 0))),
                          const SizedBox(width: 8),
                          Expanded(child: _tabBtn('Output Curves (IC vs VCE)', _graphTab == 1, () => setState(() => _graphTab = 1))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Expanded & Diszoomed Slope Chart Widget
                      SizedBox(
                        height: 460,
                        child: SlopeChartWidget(
                          title: _graphTab == 0 ? 'Input Characteristic (Iʙ vs Vʙᴇ)' : 'Output Characteristic (Iᴄ vs Vᴄᴇ)',
                          xLabel: _graphTab == 0 ? 'Vʙᴇ' : 'Vᴄᴇ',
                          yLabel: _graphTab == 0 ? 'Iʙ' : 'Iᴄ',
                          xUnit: 'V',
                          yUnit: _graphTab == 0 ? 'µA' : 'mA',
                          seriesList: _graphTab == 0 ? _inputSeries() : _outputSeries(),
                          slopeMode: _graphTab == 0 ? SlopeMode.inputResistance : SlopeMode.outputResistance,
                        ),
                      ),
                    ],

                    // ========== 6. FORMULAS & DISCUSSION ==========
                    _notionHeading(
                      key: _keyNotes,
                      num: '6',
                      title: 'Formulas & Conclusion',
                      icon: Icons.school,
                      color: Colors.indigo,
                      isExpanded: _expandNotes,
                      onToggle: () => setState(() => _expandNotes = !_expandNotes),
                      onSolo: () => _soloSection(5, _keyNotes),
                    ),
                    if (_expandNotes) ...[
                      // Formulas Card
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Theoretical Formulas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              _formulaRow('Dynamic Input Resistance', 'R', 'in', 'ΔV', 'BE', 'ΔI', 'B', 'V', 'CE'),
                              _formulaRow('Dynamic Output Resistance', 'R', 'out', 'ΔV', 'CE', 'ΔI', 'C', 'I', 'B'),
                              _formulaRow('AC Current Gain', 'β', 'ac', 'ΔI', 'C', 'ΔI', 'B', 'V', 'CE'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Discussion & Conclusion
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Discussion & Conclusion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                'The input curve behaves like a forward-biased diode: Iʙ is negligible below ~0.6V then rises quickly. '
                                'The output curves show a steep saturation region followed by a flat active region where Iᴄ is controlled by Iʙ.\n\n'
                                'Sources of error: meter internal resistance, resistor tolerances, and temperature shifts affecting β and Vʙᴇ.\n\n'
                                'Conclusion: The input and output characteristics of the ${_selectedTransistor.name} (${_selectedTransistor.type}) in common emitter configuration were measured and plotted. '
                                'Dynamic resistances (R_in, R_out) and current gain (β) are extracted directly from the slopes.',
                                style: const TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // ========== 7. MCQ QUIZ ==========
                    _notionHeading(
                      key: _keyMcq,
                      num: '7',
                      title: 'MCQ Practice',
                      icon: Icons.quiz,
                      color: Colors.green,
                      isExpanded: _expandMcq,
                      onToggle: () =>
                          setState(() => _expandMcq = !_expandMcq),
                      onSolo: () => _soloSection(6, _keyMcq),
                    ),
                    if (_expandMcq) ...[
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 720,
                          child: const McqScreen(),
                        ),
                      ),
                    ],
                    // ========== 8. LAB RECORD REPORT ==========
                    _notionHeading(
                      key: _keyReport,
                      num: '8',
                      title: 'Lab Record Report',
                      icon: Icons.menu_book,
                      color: Colors.indigo,
                      isExpanded: _expandReport,
                      onToggle: () =>
                          setState(() => _expandReport = !_expandReport),
                      onSolo: () => _soloSection(7, _keyReport),
                    ),
                    if (_expandReport) ...[
                      Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF1A237E), const Color(0xFF283593)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.menu_book, color: Colors.amber, size: 28),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Lab Record — Experiment 05',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'BJT Common Emitter Characteristics\n10 pages • Observation tables • Calculations • Results',
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotebookViewScreen()),
                                  ),
                                  icon: const Icon(Icons.open_in_full, size: 18),
                                  label: const Text('Open Lab Record', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  // ========== 9. INDUSTRIAL BENEFITS ==========
                  _notionHeading(
                    key: _keyIndustrial,
                    num: '9',
                    title: 'How This App Helps Industry',
                    icon: Icons.precision_manufacturing,
                    color: Colors.deepOrange,
                    isExpanded: _expandIndustrial,
                    onToggle: () => setState(() => _expandIndustrial = !_expandIndustrial),
                    onSolo: () => _soloSection(8, _keyIndustrial),
                  ),
                  if (_expandIndustrial) ...[
                    const SizedBox(height: 8),
                    _industrialBenefitsSection(),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  // ---- Simple helper widgets ----

  Widget _transistorSelectorCard(ColorScheme cs) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                const Text(
                  'Transistor Selection (BJT):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedTransistor.type == 'NPN'
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTransistor.type == 'NPN' ? Colors.blue : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_selectedTransistor.type} • β=${_selectedTransistor.beta.round()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _selectedTransistor.type == 'NPN' ? Colors.blue : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Transistor Chips / Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kTransistors.map((t) {
                  final isSelected = t.name == _selectedTransistor.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      avatar: CircleAvatar(
                        radius: 8,
                        backgroundColor: t.type == 'NPN' ? Colors.blue : Colors.orange,
                        child: Text(
                          t.type[0],
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      label: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedTransistor = t;
                            _loadDefaults();
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _quickNavBar(ColorScheme cs, bool isDark) {
    final allExpanded = _expandTheory && _expandCircuit && _expandSimulation && _expandTables && _expandGraphs && _expandNotes && _expandMcq && _expandReport && _expandIndustrial;

    final items = [
      {'title': 'Theory', 'icon': Icons.menu_book, 'color': Colors.blue, 'expanded': _expandTheory, 'key': _keyTheory, 'idx': 0},
      {'title': 'Circuit', 'icon': Icons.cable, 'color': Colors.orange, 'expanded': _expandCircuit, 'key': _keyCircuit, 'idx': 1},
      {'title': 'Simulation', 'icon': Icons.precision_manufacturing, 'color': Colors.deepOrange, 'expanded': _expandSimulation, 'key': _keySimulation, 'idx': 2},
      {'title': 'Tables', 'icon': Icons.table_chart, 'color': Colors.teal, 'expanded': _expandTables, 'key': _keyTables, 'idx': 3},
      {'title': 'Graphs', 'icon': Icons.show_chart, 'color': Colors.purple, 'expanded': _expandGraphs, 'key': _keyGraphs, 'idx': 4},
      {'title': 'Notes', 'icon': Icons.school, 'color': Colors.indigo, 'expanded': _expandNotes, 'key': _keyNotes, 'idx': 5},
      {'title': 'MCQs', 'icon': Icons.quiz, 'color': Colors.green, 'expanded': _expandMcq, 'key': _keyMcq, 'idx': 6},
      {'title': 'Lab Record', 'icon': Icons.menu_book, 'color': Colors.indigo, 'expanded': _expandReport, 'key': _keyReport, 'idx': 7},
      {'title': 'Industry', 'icon': Icons.factory, 'color': Colors.deepOrange, 'expanded': _expandIndustrial, 'key': _keyIndustrial, 'idx': 8},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.6),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25), width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...items.map((item) {
                  final isExp = item['expanded'] as bool;
                  final color = item['color'] as Color;
                  final title = item['title'] as String;
                  final icon = item['icon'] as IconData;
                  final key = item['key'] as GlobalKey;
                  final idx = item['idx'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _scrollToSection(key, idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isExp ? color.withValues(alpha: 0.14) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isExp ? color : cs.outlineVariant.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: isExp ? color : cs.onSurfaceVariant),
                            const SizedBox(width: 3.5),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isExp ? FontWeight.bold : FontWeight.normal,
                                color: isExp ? color : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2.5),
                            Icon(
                              isExp ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              size: 12,
                              color: isExp ? color : cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              size: 17,
              color: cs.primary,
            ),
            tooltip: allExpanded ? 'Collapse All' : 'Expand All',
            onPressed: () => _toggleAllSections(!allExpanded),
          ),
        ],
      ),
    );
  }

  Widget _industrialBenefitsSection() {
    final benefits = [
      {
        'icon': Icons.security,
        'color': const Color(0xFF1565C0),
        'title': 'Zero Component Damage',
        'desc': 'Test voltage and current limits virtually without burning expensive silicon transistors.',
        'fact': '100% Safe Testing',
      },
      {
        'icon': Icons.savings,
        'color': const Color(0xFF2E7D32),
        'title': 'Cuts Hardware Cost',
        'desc': 'Replaces dedicated ₹2L+ curve tracer benches with a mobile testing suite.',
        'fact': 'Saves ₹2 Lakhs+',
      },
      {
        'icon': Icons.cloud_done,
        'color': const Color(0xFF6A1B9A),
        'title': 'Cloud Data Logging',
        'desc': 'Directly saves every reading to PostgreSQL database with device timestamp.',
        'fact': 'Zero Data Loss',
      },
      {
        'icon': Icons.speed,
        'color': const Color(0xFFC62828),
        'title': 'Instant Calculations',
        'desc': 'Extracts β, dynamic input & output resistance instantly without manual graphing.',
        'fact': 'Instant Output',
      },
      {
        'icon': Icons.article,
        'color': const Color(0xFFE65100),
        'title': 'Auto Lab Reports',
        'desc': 'Generates ready-to-verify digital reports with observation tables and signatures.',
        'fact': 'Ready Report',
      },
      {
        'icon': Icons.phone_android,
        'color': const Color(0xFF00695C),
        'title': 'Shop Floor Portable',
        'desc': 'Engineers and technicians can test circuits anywhere directly from any phone.',
        'fact': 'Portable & Fast',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.precision_manufacturing, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('How This App Helps Industry',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Replaces costly physical bench equipment, eliminates component burnout risks, and delivers automated cloud-synced reports.',
                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: benefits.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, i) {
            final item = benefits[i];
            final color = item['color'] as Color;
            return Container(
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(70)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: Icon(item['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(item['title'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(item['desc'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF424242), height: 1.35)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: Text(item['fact'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7B1FA2).withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF7B1FA2), size: 18),
                  SizedBox(width: 8),
                  Text('Core Industry Advantages',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7B1FA2))),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                ('Saves Hardware Budget', 'No costly curve tracers or DC meters needed'),
                ('Zero Burnout Risk', 'Safe virtual testing prevents damaging real parts'),
                ('Cloud Traceability', 'Readings logged directly to PostgreSQL with timestamps'),
                ('Fast Documentation', 'Auto-generated lab report tables ready for sign-off'),
              ].map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, color: Color(0xFF7B1FA2), size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: '${e.$1}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black87)),
                            TextSpan(text: e.$2, style: const TextStyle(fontSize: 11.5, color: Color(0xFF424242))),
                          ])),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notionHeading({
    required GlobalKey key,
    required String num,
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onSolo,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isExpanded ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isExpanded ? 0.4 : 0.2),
          width: 0.9,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.arrow_right, color: color, size: 22),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  num,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isExpanded)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: Icon(Icons.fullscreen_rounded, size: 18, color: color),
                  tooltip: 'Focus only on this section (collapse others)',
                  onPressed: onSolo,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meter(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _slider(String label, double val, double mn, double mx, String unit, ValueChanged<double> cb) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text('${val.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: val.clamp(mn, mx), min: mn, max: mx, onChanged: cb),
      ],
    );
  }

  Widget _tabBtn(String text, bool selected, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.teal : Colors.grey.shade200,
        foregroundColor: selected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _formulaRow(String label, String sym, String symSub, String num, String numSub, String den, String denSub, String cond, String condSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(text: '• $label:  '),
            TextSpan(text: sym, style: const TextStyle(fontWeight: FontWeight.bold)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0.5, 3),
                child: Text(symSub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            const TextSpan(text: ' = '),
            TextSpan(text: num, style: const TextStyle(fontWeight: FontWeight.bold)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0.5, 3),
                child: Text(numSub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            const TextSpan(text: ' / '),
            TextSpan(text: den, style: const TextStyle(fontWeight: FontWeight.bold)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0.5, 3),
                child: Text(denSub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            TextSpan(text: '  (with $cond', style: const TextStyle(color: Colors.grey)),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0.5, 3),
                child: Text(condSub, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            const TextSpan(text: ' constant)', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _dataTable(ColorScheme cs) {
    final controllers = _dataTab == 0 ? [_inC1, _inC2, _inC3] : [_outC1, _outC2, _outC3];
    final focusNodes = _dataTab == 0 ? [_inF1, _inF2, _inF3] : [_outF1, _outF2, _outF3];
    final headers = _dataTab == 0 ? ['Vʙʙ (V)', 'Vʙᴇ (V)', 'Iʙ (µA)'] : ['Vᴄᴄ (V)', 'Vᴄᴇ (V)', 'Iᴄ (mA)'];
    final count = controllers[0].length;
    final syncFn = _dataTab == 0 ? _syncInput : _syncOutput;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 28, child: Center(child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                  for (final h in headers)
                    Expanded(child: Center(child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                  const SizedBox(width: 32, child: Center(child: Text('Del', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
                ],
              ),
            ),
            const Divider(height: 1),
            // Rows
            for (int i = 0; i < count; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                    for (int j = 0; j < 3; j++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextField(
                            controller: controllers[j][i],
                            focusNode: focusNodes[j][i],
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => syncFn(),
                            onSubmitted: (_) => _moveToNextCell(i, j),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeRow(i),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < count - 1)
                Divider(height: 1, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.3)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _theoryCard(ColorScheme cs) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BJT Common Emitter Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'A bipolar junction transistor (${_selectedTransistor.name} ${_selectedTransistor.type}) has three terminals: Emitter, Base, Collector. '
              'In the common emitter (CE) configuration, the emitter is common to both input and output circuits. '
              'The base-emitter junction is forward-biased and the collector-base junction is reverse-biased.\n\n'
              '• Input characteristic: Iʙ vs Vʙᴇ for constant Vᴄᴇ (forward diode behavior)\n'
              '• Output characteristic: Iᴄ vs Vᴄᴇ for constant Iʙ (saturation and active amplification regions)\n\n'
              'DC current gain: β_dc = Iᴄ / Iʙ (Nominal β ≈ ${_selectedTransistor.beta.round()})\n'
              'AC current gain: β_ac = ΔIᴄ / ΔIʙ (constant Vᴄᴇ)',
              style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            const Text('Objectives', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '1. Design and simulate the BJT circuit schematic with ${_selectedTransistor.name}\n'
              '2. Take readings and plot input & output characteristic curves\n'
              '3. Determine dynamic input resistance R_in, output resistance R_out, and current gain β',
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Equipment: ${_selectedTransistor.name} ${_selectedTransistor.type}, 1 kΩ & 100 kΩ resistors, 0-30V dual DC power supply, voltmeter, microammeter, milliammeter.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
