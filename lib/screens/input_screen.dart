import 'package:flutter/material.dart';
import '../models/input_reading.dart';
import '../services/experiment_service.dart';
import 'graph_screen.dart';

/// Screen for recording BJT Input Characteristics (IB vs VBE).
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  static const int _initialRowCount = 11;
  static const int _maxRowCount = 30;

  double _selectedVce = 1.0;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  late List<TextEditingController> _vbbControllers;
  late List<TextEditingController> _vbeControllers;
  late List<TextEditingController> _ibControllers;

  late List<FocusNode> _vbbFocusNodes;
  late List<FocusNode> _vbeFocusNodes;
  late List<FocusNode> _ibFocusNodes;

  int _rowCount = _initialRowCount;

  @override
  void initState() {
    super.initState();
    _initRows(_initialRowCount);
    _loadFromService();
  }

  void _initRows(int count) {
    _rowCount = count;
    _vbbControllers = List.generate(count, (_) => TextEditingController());
    _vbeControllers = List.generate(count, (_) => TextEditingController());
    _ibControllers  = List.generate(count, (_) => TextEditingController());

    _vbbFocusNodes = List.generate(count, (_) => FocusNode());
    _vbeFocusNodes = List.generate(count, (_) => FocusNode());
    _ibFocusNodes  = List.generate(count, (_) => FocusNode());
  }

  void _disposeRows() {
    for (int i = 0; i < _rowCount; i++) {
      _vbbControllers[i].dispose();
      _vbeControllers[i].dispose();
      _ibControllers[i].dispose();

      _vbbFocusNodes[i].dispose();
      _vbeFocusNodes[i].dispose();
      _ibFocusNodes[i].dispose();
    }
  }

  @override
  void dispose() {
    _disposeRows();
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewRow() {
    if (_rowCount >= _maxRowCount) return;

    final newVbbCtrl = TextEditingController();
    final newVbeCtrl = TextEditingController();
    final newIbCtrl  = TextEditingController();

    final newVbbFocus = FocusNode();
    final newVbeFocus = FocusNode();
    final newIbFocus  = FocusNode();

    setState(() {
      _rowCount++;
      _vbbControllers.add(newVbbCtrl);
      _vbeControllers.add(newVbeCtrl);
      _ibControllers.add(newIbCtrl);

      _vbbFocusNodes.add(newVbbFocus);
      _vbeFocusNodes.add(newVbeFocus);
      _ibFocusNodes.add(newIbFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      newVbbFocus.requestFocus();
    });
  }

  void _loadFromService() {
    final readings = ExperimentService.liveInputReadings
        .where((r) => r.vce == _selectedVce)
        .toList();

    final targetCount = readings.length > _initialRowCount
        ? (readings.length <= _maxRowCount ? readings.length : _maxRowCount)
        : _initialRowCount;

    if (targetCount != _rowCount) {
      _disposeRows();
      _initRows(targetCount);
    }

    for (int i = 0; i < _rowCount; i++) {
      if (i < readings.length) {
        _vbbControllers[i].text = readings[i].vbb.toString();
        _vbeControllers[i].text = readings[i].vbe.toString();
        _ibControllers[i].text  = readings[i].ib.toString();
      } else {
        _vbbControllers[i].clear();
        _vbeControllers[i].clear();
        _ibControllers[i].clear();
      }
    }
  }

  void _syncAllRowsToService() {
    final updatedList = <InputReading>[];

    for (int i = 0; i < _rowCount; i++) {
      final vbb = double.tryParse(_vbbControllers[i].text.trim());
      final vbe = double.tryParse(_vbeControllers[i].text.trim());
      final ib  = double.tryParse(_ibControllers[i].text.trim());

      if (vbb != null && vbe != null && ib != null) {
        updatedList.add(InputReading(
          vbb: vbb,
          vce: _selectedVce,
          vbe: vbe,
          ib: ib,
        ));
      }
    }

    final otherVce = ExperimentService.liveInputReadings
        .where((r) => r.vce != _selectedVce)
        .toList();

    ExperimentService.liveInputReadings = [...otherVce, ...updatedList];
  }

  void _onCellSubmitted(int row, int col) {
    if (col == 0) {
      _vbeFocusNodes[row].requestFocus();
    } else if (col == 1) {
      _ibFocusNodes[row].requestFocus();
    } else if (col == 2) {
      if (row < _rowCount - 1) {
        _vbbFocusNodes[row + 1].requestFocus();
      } else if (_rowCount < _maxRowCount) {
        _addNewRow();
      } else {
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _clearTable() {
    _disposeRows();
    _initRows(_initialRowCount);
    _syncAllRowsToService();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Table cleared. Reset to 11 rows.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _fillSampleData() {
    final steps = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];

    if (_rowCount != _initialRowCount) {
      _disposeRows();
      _initRows(_initialRowCount);
    }

    for (int i = 0; i < _rowCount; i++) {
      if (i < steps.length) {
        final vbb = steps[i];
        double vbe = 0.0, ib = 0.0;
        if (vbb > 0.6) {
          vbe = 0.65 + (vbb / 5.0) * 0.07;
          ib = (vbb - vbe) / 1.0 * 1000.0 * (_selectedVce == 2.0 ? 0.98 : 1.0);
        }
        _vbbControllers[i].text = vbb.toStringAsFixed(1);
        _vbeControllers[i].text = vbe.toStringAsFixed(3);
        _ibControllers[i].text  = ib.toStringAsFixed(1);
      } else {
        _vbbControllers[i].clear();
        _vbeControllers[i].clear();
        _ibControllers[i].clear();
      }
    }
    _syncAllRowsToService();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample observations filled (11 rows for VCE = $_selectedVce V).'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveToCloud() async {
    setState(() => _isSaving = true);
    _syncAllRowsToService();
    try {
      await ExperimentService.saveExperimentSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors
    final headerBg = isDark ? cs.primaryContainer : const Color(0xFFE0E7FF);
    final headerText = isDark ? cs.onPrimaryContainer : const Color(0xFF1E3A8A);
    final headerBorder = isDark ? cs.primary.withValues(alpha: 0.5) : Colors.indigo.shade200;
    final evenRowBg = isDark ? cs.surface : Colors.white;
    final oddRowBg = isDark ? cs.surfaceContainerHighest : const Color(0xFFF9FAFB);
    final rowBorder = isDark ? cs.outline.withValues(alpha: 0.3) : Colors.grey.shade200;
    final tableBorder = isDark ? cs.outline : Colors.grey.shade300;
    final cellBorder = isDark ? cs.outline.withValues(alpha: 0.4) : Colors.grey.shade300;
    final rowNumColor = isDark ? cs.onSurface.withValues(alpha: 0.6) : Colors.grey.shade700;
    final hintColor = isDark ? cs.onSurface.withValues(alpha: 0.35) : Colors.grey.shade400;
    final infoBg = isDark ? cs.primaryContainer.withValues(alpha: 0.3) : Colors.blue.shade50;
    final infoBorder = isDark ? cs.primary.withValues(alpha: 0.4) : Colors.blue.shade200;
    final infoText = isDark ? cs.onSurface : Colors.blue.shade900;
    final rowCountText = isDark ? cs.onSurface.withValues(alpha: 0.6) : Colors.grey.shade700;
    final addRowText = isDark ? cs.primary : Colors.teal.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Characteristics (IB vs VBE)'),
        actions: [
          IconButton(
            tooltip: 'View Live Graph',
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              _syncAllRowsToService();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GraphScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Parameter Denotations Card
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: infoBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: infoBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parameter Denotations:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: infoText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Vbb : Base DC Supply Voltage (V)\n'
                    '• Vbe : Base-Emitter Voltage (V)\n'
                    '• IB  : Base Current (µA)\n'
                    '• Vce : Collector-Emitter Voltage (Held constant at $_selectedVce V)\n'
                    '• Press Enter to move to next column → next row (up to 30 rows).',
                    style: TextStyle(fontSize: 11, color: infoText, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Fixed VCE Selector
            SegmentedButton<double>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 1.0, label: Text('VCE = 1.0 V', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 2.0, label: Text('VCE = 2.0 V', style: TextStyle(fontSize: 12))),
              ],
              selected: {_selectedVce},
              onSelectionChanged: (set) {
                _syncAllRowsToService();
                setState(() {
                  _selectedVce = set.first;
                  _loadFromService();
                });
              },
            ),
            const SizedBox(height: 10),

            // Toolbar Controls
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                  label: const Text('Clear Table', style: TextStyle(fontSize: 11.5, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: _clearTable,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_fix_high, size: 16, color: Colors.blue),
                  label: const Text('Fill Sample Data', style: TextStyle(fontSize: 11.5, color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: _fillSampleData,
                ),
                ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Data', style: TextStyle(fontSize: 11.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: _isSaving ? null : _saveToCloud,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Rows Count Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Observation Rows: $_rowCount / $_maxRowCount',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rowCountText),
                  ),
                  if (_rowCount < _maxRowCount)
                    InkWell(
                      onTap: _addNewRow,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          '+ Add Row',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: addRowText),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Observation Table Grid
            Container(
              decoration: BoxDecoration(
                color: evenRowBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tableBorder, width: 1.2),
              ),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1.0), // Row #
                  1: FlexColumnWidth(2.8), // Vbb (V)
                  2: FlexColumnWidth(2.8), // Vbe (V)
                  3: FlexColumnWidth(3.0), // IB (µA)
                },
                children: [
                  // ── Header Row ──
                  TableRow(
                    decoration: BoxDecoration(
                      color: headerBg,
                      border: Border(bottom: BorderSide(color: headerBorder, width: 1.5)),
                    ),
                    children: [
                      _buildHeaderCell('#', 'No.', headerText, headerBorder),
                      _buildHeaderCell('Vbb', '(V)', headerText, headerBorder),
                      _buildHeaderCell('Vbe', '(V)', headerText, headerBorder),
                      _buildHeaderCell('IB', '(µA)', headerText, headerBorder),
                    ],
                  ),

                  // ── Observation Rows ──
                  ...List.generate(_rowCount, (r) {
                    final displayRow = r + 1;
                    final isEven = r % 2 == 0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? evenRowBg : oddRowBg,
                        border: Border(bottom: BorderSide(color: rowBorder, width: 0.8)),
                      ),
                      children: [
                        // Row Index
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: cellBorder, width: 0.8)),
                          ),
                          child: Text(
                            '$displayRow',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: rowNumColor,
                            ),
                          ),
                        ),

                        // Cell 1: Vbb
                        _buildEditableCell(_vbbControllers[r], _vbbFocusNodes[r], r, 0, '0.0', cellBorder, hintColor),

                        // Cell 2: Vbe
                        _buildEditableCell(_vbeControllers[r], _vbeFocusNodes[r], r, 1, '0.0', cellBorder, hintColor),

                        // Cell 3: IB
                        _buildEditableCell(_ibControllers[r], _ibFocusNodes[r], r, 2, '0.0', cellBorder, hintColor),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, String unit, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
          ),
          Text(
            unit,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
    TextEditingController controller,
    FocusNode focusNode,
    int row,
    int col,
    String hint,
    Color borderColor,
    Color hintColor,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _onCellSubmitted(row, col),
        onChanged: (_) => _syncAllRowsToService(),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 11),
        ),
      ),
    );
  }
}
