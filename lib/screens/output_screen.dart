import 'package:flutter/material.dart';
import '../models/output_reading.dart';
import '../services/experiment_service.dart';
import 'graph_screen.dart';

/// Screen for recording BJT Output Characteristics (IC vs VCE).
class OutputScreen extends StatefulWidget {
  const OutputScreen({super.key});

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  static const int _initialRowCount = 11;
  static const int _maxRowCount = 30;

  double _selectedIb = 4.3; // Fixed base current: 4.3 µA or 10.0 µA
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  late List<TextEditingController> _vccControllers;
  late List<TextEditingController> _vceControllers;
  late List<TextEditingController> _icControllers;

  late List<FocusNode> _vccFocusNodes;
  late List<FocusNode> _vceFocusNodes;
  late List<FocusNode> _icFocusNodes;

  int _rowCount = _initialRowCount;

  @override
  void initState() {
    super.initState();
    _initRows(_initialRowCount);
    _loadFromService();
  }

  void _initRows(int count) {
    _rowCount = count;
    _vccControllers = List.generate(count, (_) => TextEditingController());
    _vceControllers = List.generate(count, (_) => TextEditingController());
    _icControllers  = List.generate(count, (_) => TextEditingController());

    _vccFocusNodes = List.generate(count, (_) => FocusNode());
    _vceFocusNodes = List.generate(count, (_) => FocusNode());
    _icFocusNodes  = List.generate(count, (_) => FocusNode());
  }

  void _disposeRows() {
    for (int i = 0; i < _rowCount; i++) {
      _vccControllers[i].dispose();
      _vceControllers[i].dispose();
      _icControllers[i].dispose();

      _vccFocusNodes[i].dispose();
      _vceFocusNodes[i].dispose();
      _icFocusNodes[i].dispose();
    }
  }

  @override
  void dispose() {
    _disposeRows();
    _scrollController.dispose();
    super.dispose();
  }

  /// Appends one new row dynamically if under maximum of 30 rows
  void _addNewRow() {
    if (_rowCount >= _maxRowCount) return;

    final newVccCtrl = TextEditingController();
    final newVceCtrl = TextEditingController();
    final newIcCtrl  = TextEditingController();

    final newVccFocus = FocusNode();
    final newVceFocus = FocusNode();
    final newIcFocus  = FocusNode();

    setState(() {
      _rowCount++;
      _vccControllers.add(newVccCtrl);
      _vceControllers.add(newVceCtrl);
      _icControllers.add(newIcCtrl);

      _vccFocusNodes.add(newVccFocus);
      _vceFocusNodes.add(newVceFocus);
      _icFocusNodes.add(newIcFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      newVccFocus.requestFocus();
    });
  }

  /// Loads current readings for selected IB from the service into rows
  void _loadFromService() {
    final readings = ExperimentService.liveOutputReadings
        .where((r) => (r.ib - _selectedIb).abs() < 0.1)
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
        _vccControllers[i].text = readings[i].vcc.toString();
        _vceControllers[i].text = readings[i].vce.toString();
        _icControllers[i].text  = readings[i].ic.toString();
      } else {
        _vccControllers[i].clear();
        _vceControllers[i].clear();
        _icControllers[i].clear();
      }
    }
  }

  /// Synchronizes all non-empty rows back to the live experiment service
  void _syncAllRowsToService() {
    final updatedList = <OutputReading>[];

    for (int i = 0; i < _rowCount; i++) {
      final vcc = double.tryParse(_vccControllers[i].text.trim());
      final vce = double.tryParse(_vceControllers[i].text.trim());
      final ic  = double.tryParse(_icControllers[i].text.trim());

      if (vcc != null && vce != null && ic != null) {
        updatedList.add(OutputReading(
          vcc: vcc,
          ib: _selectedIb,
          vce: vce,
          ic: ic,
        ));
      }
    }

    final otherIb = ExperimentService.liveOutputReadings
        .where((r) => (r.ib - _selectedIb).abs() >= 0.1)
        .toList();

    ExperimentService.liveOutputReadings = [...otherIb, ...updatedList];
  }

  /// Keyboard Enter navigation: Column 0 -> Column 1 -> Column 2 -> Next Row (or add new row up to 30)
  void _onCellSubmitted(int row, int col) {
    if (col == 0) {
      _vceFocusNodes[row].requestFocus();
    } else if (col == 1) {
      _icFocusNodes[row].requestFocus();
    } else if (col == 2) {
      if (row < _rowCount - 1) {
        _vccFocusNodes[row + 1].requestFocus();
      } else if (_rowCount < _maxRowCount) {
        _addNewRow();
      } else {
        FocusScope.of(context).unfocus();
      }
    }
  }

  /// Clears table and resets to 11 empty rows
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

  /// Fills standard 11 textbook/lab steps
  void _fillSampleData() {
    final steps = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
    final isHigherIb = _selectedIb > 5.0;

    if (_rowCount != _initialRowCount) {
      _disposeRows();
      _initRows(_initialRowCount);
    }

    for (int i = 0; i < _rowCount; i++) {
      if (i < steps.length) {
        final vcc = steps[i];
        double vce = vcc * (isHigherIb ? 0.85 : 0.9);
        double ic = isHigherIb ? 1.50 : 0.65;
        if (vcc <= 1.0) {
          vce = vcc * (isHigherIb ? 0.25 : 0.2);
          ic = vcc * (isHigherIb ? 1.4 : 0.6);
        }
        _vccControllers[i].text = vcc.toStringAsFixed(1);
        _vceControllers[i].text = vce.toStringAsFixed(2);
        _icControllers[i].text  = ic.toStringAsFixed(2);
      } else {
        _vccControllers[i].clear();
        _vceControllers[i].clear();
        _icControllers[i].clear();
      }
    }
    _syncAllRowsToService();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample observations filled (11 rows for IB = $_selectedIb µA).'),
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

    // Theme-adaptive colors
    final headerBg = isDark ? cs.tertiaryContainer : const Color(0xFFCCFBF1);
    final headerText = isDark ? cs.onTertiaryContainer : const Color(0xFF115E59);
    final headerBorder = isDark ? cs.tertiary.withValues(alpha: 0.5) : Colors.teal.shade300;
    final evenRowBg = isDark ? cs.surface : Colors.white;
    final oddRowBg = isDark ? cs.surfaceContainerHighest : const Color(0xFFF9FAFB);
    final rowBorder = isDark ? cs.outline.withValues(alpha: 0.3) : Colors.grey.shade200;
    final tableBorder = isDark ? cs.outline : Colors.grey.shade300;
    final cellBorder = isDark ? cs.outline.withValues(alpha: 0.4) : Colors.grey.shade300;
    final rowNumColor = isDark ? cs.onSurface.withValues(alpha: 0.6) : Colors.grey.shade700;
    final hintColor = isDark ? cs.onSurface.withValues(alpha: 0.35) : Colors.grey.shade400;
    final infoBg = isDark ? cs.tertiaryContainer.withValues(alpha: 0.25) : Colors.teal.shade50;
    final infoBorder = isDark ? cs.tertiary.withValues(alpha: 0.4) : Colors.teal.shade200;
    final infoText = isDark ? cs.onSurface : Colors.teal.shade900;
    final rowCountText = isDark ? cs.onSurface.withValues(alpha: 0.6) : Colors.grey.shade700;
    final addRowText = isDark ? cs.primary : Colors.teal.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Output Characteristics (IC vs VCE)'),
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
            // Parameter Denotations Guide Card
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
                    '• Vcc : Collector DC Supply Voltage (V)\n'
                    '• Vce : Collector-Emitter Voltage (V)\n'
                    '• IC  : Collector Current (mA)\n'
                    '• IB  : Base Current (Held constant at $_selectedIb µA)\n'
                    '• Press Enter to move to next column → next row (up to 30 rows).',
                    style: TextStyle(fontSize: 11, color: infoText, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Fixed IB Selector
            SegmentedButton<double>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: 4.3, label: Text('IB = 4.3 µA (1MΩ)', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 10.0, label: Text('IB = 10.0 µA (470kΩ)', style: TextStyle(fontSize: 12))),
              ],
              selected: {_selectedIb},
              onSelectionChanged: (set) {
                _syncAllRowsToService();
                setState(() {
                  _selectedIb = set.first;
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
                  icon: const Icon(Icons.auto_fix_high, size: 16, color: Colors.teal),
                  label: const Text('Fill Sample Data', style: TextStyle(fontSize: 11.5, color: Colors.teal)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
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
                  1: FlexColumnWidth(2.8), // Vcc (V)
                  2: FlexColumnWidth(2.8), // Vce (V)
                  3: FlexColumnWidth(3.0), // IC (mA)
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
                      _buildHeaderCell('Vcc', '(V)', headerText, headerBorder),
                      _buildHeaderCell('Vce', '(V)', headerText, headerBorder),
                      _buildHeaderCell('IC', '(mA)', headerText, headerBorder),
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

                        // Cell 1: Vcc
                        _buildEditableCell(_vccControllers[r], _vccFocusNodes[r], r, 0, '0.0', cellBorder, hintColor),

                        // Cell 2: Vce
                        _buildEditableCell(_vceControllers[r], _vceFocusNodes[r], r, 1, '0.0', cellBorder, hintColor),

                        // Cell 3: IC
                        _buildEditableCell(_icControllers[r], _icFocusNodes[r], r, 2, '0.0', cellBorder, hintColor),
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
