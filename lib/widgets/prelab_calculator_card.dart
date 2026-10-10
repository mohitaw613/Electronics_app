import 'package:flutter/material.dart';
import '../models/prelab_calculation.dart';

class PreLabCalculatorCard extends StatefulWidget {
  final double? liveMeasuredVce;
  final double? liveMeasuredIc;

  const PreLabCalculatorCard({
    super.key,
    this.liveMeasuredVce,
    this.liveMeasuredIc,
  });

  @override
  State<PreLabCalculatorCard> createState() => _PreLabCalculatorCardState();
}

class _PreLabCalculatorCardState extends State<PreLabCalculatorCard> {
  final TextEditingController _vccCtrl = TextEditingController(text: '10.0');
  final TextEditingController _rbCtrl  = TextEditingController(text: '100.0');
  final TextEditingController _rcCtrl  = TextEditingController(text: '1.0');
  final TextEditingController _betaCtrl = TextEditingController(text: '150.0');

  double _vcc = 10.0;
  double _rb = 100.0;
  double _rc = 1.0;
  double _beta = 150.0;

  @override
  void dispose() {
    _vccCtrl.dispose();
    _rbCtrl.dispose();
    _rcCtrl.dispose();
    _betaCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _vcc = double.tryParse(_vccCtrl.text) ?? 10.0;
      _rb  = double.tryParse(_rbCtrl.text) ?? 100.0;
      _rc  = double.tryParse(_rcCtrl.text) ?? 1.0;
      _beta = double.tryParse(_betaCtrl.text) ?? 150.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final result = PreLabCalculator.calculateDcBias(
      vcc: _vcc,
      rb: _rb,
      rc: _rc,
      beta: _beta,
    );

    final bool isValid = result['isValid'] == true;
    final double theoVce = isValid ? (result['vCE'] as double) : 0.0;
    final double theoIc  = isValid ? (result['iC_mA'] as double) : 0.0;
    final double theoIb  = isValid ? (result['iB_uA'] as double) : 0.0;
    final double theoVb  = isValid ? (result['vB'] as double) : 0.0;
    final double theoVe  = isValid ? (result['vE'] as double) : 0.0;
    final String stateStr = isValid ? (result['operatingState'] as String) : 'Invalid';

    // Errors with measured values if available
    double? vceErr;
    double? icErr;
    if (widget.liveMeasuredVce != null && isValid) {
      vceErr = PreLabCalculator.percentError(theoVce, widget.liveMeasuredVce!);
    }
    if (widget.liveMeasuredIc != null && isValid) {
      icErr = PreLabCalculator.percentError(theoIc, widget.liveMeasuredIc!);
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Theoretical Calculations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (result['isSaturated'] == true ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: result['isSaturated'] == true ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input fields row
            Row(
              children: [
                _buildSmallInputField('Vᴄᴄ (V)', _vccCtrl),
                const SizedBox(width: 8),
                _buildSmallInputField('Rʙ (kΩ)', _rbCtrl),
                const SizedBox(width: 8),
                _buildSmallInputField('Rᴄ (kΩ)', _rcCtrl),
                const SizedBox(width: 8),
                _buildSmallInputField('β (Gain)', _betaCtrl),
              ],
            ),
            const SizedBox(height: 14),

            // Theoretical Results Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('Theo Vʙ', '${theoVb.toStringAsFixed(2)} V', Colors.blue),
                      _buildMetricItem('Theo Vᴇ', '${theoVe.toStringAsFixed(2)} V', Colors.grey),
                      _buildMetricItem('Theo Iʙ', '${theoIb.toStringAsFixed(1)} µA', Colors.indigo),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('Theo Vᴄᴇ', '${theoVce.toStringAsFixed(2)} V', Colors.deepOrange),
                      _buildMetricItem('Theo Iᴄ', '${theoIc.toStringAsFixed(2)} mA', Colors.teal),
                    ],
                  ),
                ],
              ),
            ),

            // Comparison & Percent Error Card (if measured live values provided)
            if (widget.liveMeasuredVce != null || widget.liveMeasuredIc != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Theoretical vs Measured Percent Error:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (widget.liveMeasuredVce != null && vceErr != null)
                    Expanded(
                      child: _buildErrorChip(
                        parameter: 'Vᴄᴇ',
                        theo: theoVce,
                        meas: widget.liveMeasuredVce!,
                        unit: 'V',
                        errorPct: vceErr,
                      ),
                    ),
                  if (widget.liveMeasuredVce != null && widget.liveMeasuredIc != null)
                    const SizedBox(width: 8),
                  if (widget.liveMeasuredIc != null && icErr != null)
                    Expanded(
                      child: _buildErrorChip(
                        parameter: 'Iᴄ',
                        theo: theoIc,
                        meas: widget.liveMeasuredIc!,
                        unit: 'mA',
                        errorPct: icErr,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInputField(String label, TextEditingController ctrl) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onInputChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildErrorChip({
    required String parameter,
    required double theo,
    required double meas,
    required String unit,
    required double errorPct,
  }) {
    Color badgeColor = Colors.green;
    if (errorPct > 15) {
      badgeColor = Colors.red;
    } else if (errorPct > 5) {
      badgeColor = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(parameter, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor)),
              Text('${errorPct.toStringAsFixed(1)}% Error',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeColor)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Theo: ${theo.toStringAsFixed(2)}$unit  |  Meas: ${meas.toStringAsFixed(2)}$unit',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
