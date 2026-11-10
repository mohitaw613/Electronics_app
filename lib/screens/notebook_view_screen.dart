import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NotebookViewScreen extends StatefulWidget {
  final bool embedded;
  const NotebookViewScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends State<NotebookViewScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _pages = _buildAllPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (!widget.embedded) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pages.length) return;
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ─── Page Factory ────────────────────────────────────────────────────────────

  List<Widget> _buildAllPages() => [
        _coverPage(),
        _objectivePage(),
        _apparatusPage(),
        _theoryPage(),
        _procedurePage(),
        _inputObservationTable(),
        _outputObservationTable(),
        _calculationsPage(),
        _resultPage(),
        _conclusionPage(),
      ];

  // ─── Shared Styles ───────────────────────────────────────────────────────────

  static const Color _pageColor   = Color(0xFFFFFDF5);
  static const Color _headerColor = Color(0xFF1A237E);  // dark navy
  static const Color _accentColor = Color(0xFFD32F2F);  // red accent
  static const Color _lineColor   = Color(0xFFBBDEFB);  // ruled-line blue
  static const Color _textColor   = Color(0xFF000000);  // pure black
  static const Color _subColor    = Color(0xFF212121);

  TextStyle get _headingStyle => GoogleFonts.merriweather(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: _headerColor,
      );

  TextStyle get _bodyStyle => GoogleFonts.lato(
        fontSize: 12,
        height: 1.7,
        color: _textColor,
      );

  TextStyle get _labelStyle => GoogleFonts.lato(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _subColor,
      );

  TextStyle get _smallStyle => GoogleFonts.lato(
        fontSize: 10.5,
        color: _subColor,
        height: 1.5,
      );

  TextStyle get _tableHeaderStyle => GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  TextStyle get _tableCellStyle => GoogleFonts.lato(
        fontSize: 11,
        color: _textColor,
      );

  // ─── Page Shell ──────────────────────────────────────────────────────────────

  Widget _shell({required int pageNum, required List<Widget> children}) {
    return Container(
      color: _pageColor,
      child: Column(
        children: [
          // Top ruled lines decoration
          ...List.generate(3, (_) => Container(height: 1, color: _lineColor, margin: const EdgeInsets.only(bottom: 3))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _lineColor, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NIT Rourkela — EC Lab Record', style: _smallStyle),
                Text('Page $pageNum of ${_buildAllPages().length}', style: _smallStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: _headingStyle),
            Container(height: 2, width: 60, color: _accentColor),
          ],
        ),
      );

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: _lineColor, thickness: 1.2),
      );

  Widget _bulletItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: _bodyStyle.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            Expanded(child: Text(text, style: _bodyStyle)),
          ],
        ),
      );

  Widget _numberedItem(int n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text('$n.', style: _bodyStyle.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(text, style: _bodyStyle)),
          ],
        ),
      );

  // ─── PAGES ───────────────────────────────────────────────────────────────────

  Widget _coverPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NIT ROURKELA',
                  style: GoogleFonts.merriweather(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Department of Electronics & Communication',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text('LAB RECORD', style: GoogleFonts.merriweather(fontSize: 11, letterSpacing: 3, color: _accentColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(height: 2, color: _lineColor),
                    const SizedBox(height: 10),
                    Text(
                      'Experiment 05',
                      style: GoogleFonts.merriweather(fontSize: 13, fontWeight: FontWeight.bold, color: _headerColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BJT Common Emitter\nInput & Output Characteristics',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.merriweather(fontSize: 12, color: _textColor, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _infoRow('Name', 'Mohit Awasthi'),
              _infoRow('Roll No.', '125CS0168'),
              _infoRow('Semester', '3rd Semester'),
              _infoRow('Session', '2026–27 (Even)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text('$label:', style: GoogleFonts.lato(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            Text(value, style: GoogleFonts.lato(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _objectivePage() => _shell(
        pageNum: 2,
        children: [
          _sectionTitle('1. Objective'),
          _divider(),
          Text(
            'To study and plot the input and output characteristics of an NPN Bipolar Junction Transistor (BJT — BC547) connected in Common Emitter (CE) configuration, and thereby determine:',
            style: _bodyStyle,
          ),
          const SizedBox(height: 10),
          _bulletItem('The input characteristic curve: I_B vs V_BE at constant V_CE.'),
          _bulletItem('The output characteristic curve: I_C vs V_CE at constant I_B.'),
          _bulletItem('DC current gain (β_DC) = I_C / I_B.'),
          _bulletItem('AC current gain (β_AC) = ΔI_C / ΔI_B at constant V_CE.'),
          _bulletItem('Input dynamic resistance: r_in = ΔV_BE / ΔI_B.'),
          _bulletItem('Output dynamic resistance: r_out = ΔV_CE / ΔI_C at constant I_B.'),
          _divider(),
          _sectionTitle('2. Apparatus Required'),
          _divider(),
          _bulletItem('NPN Transistor: BC547'),
          _bulletItem('DC Regulated Power Supplies: 0–5V (input), 0–15V (output)'),
          _bulletItem('Digital Multimeters (×2) for V_BE, I_B, V_CE, I_C'),
          _bulletItem('Resistors: R_B = 100 kΩ, R_C = 1 kΩ'),
          _bulletItem('Breadboard and Connecting Wires'),
          _bulletItem('Graph paper / Lab Notebook'),
        ],
      );

  Widget _apparatusPage() => _shell(
        pageNum: 3,
        children: [
          _sectionTitle('3. Circuit Diagram Description'),
          _divider(),
          Text(
            'In the Common Emitter configuration, the emitter terminal is common to both the input (Base–Emitter) circuit and the output (Collector–Emitter) circuit.',
            style: _bodyStyle,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _headerColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Circuit Connections:', style: _labelStyle),
                const SizedBox(height: 8),
                _numberedItem(1, 'Connect V_BB (0–5V) in series with R_B (100 kΩ) to the Base terminal.'),
                _numberedItem(2, 'Connect V_CC (0–15V) in series with R_C (1 kΩ) to the Collector terminal.'),
                _numberedItem(3, 'Common Emitter terminal is connected to the negative of both supplies.'),
                _numberedItem(4, 'Place microammeter (µA) in base loop to measure I_B.'),
                _numberedItem(5, 'Place milliammeter (mA) in collector loop to measure I_C.'),
                _numberedItem(6, 'Voltmeter across B–E to measure V_BE; voltmeter across C–E for V_CE.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Pin Assignment — BC547 (TO-92 package):', style: _labelStyle),
          const SizedBox(height: 6),
          Row(children: [
            _pinBox('1', 'Collector'),
            const SizedBox(width: 8),
            _pinBox('2', 'Base'),
            const SizedBox(width: 8),
            _pinBox('3', 'Emitter'),
          ]),
        ],
      );

  Widget _pinBox(String pin, String name) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _headerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text('Pin $pin', style: GoogleFonts.lato(color: Colors.white70, fontSize: 10)),
              Text(name, style: GoogleFonts.lato(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _theoryPage() => _shell(
        pageNum: 4,
        children: [
          _sectionTitle('4. Theory'),
          _divider(),
          Text(
            'A BJT is a three-terminal semiconductor device with an Emitter, Base, and Collector. In CE mode, it is widely used as an amplifier and switch.',
            style: _bodyStyle,
          ),
          const SizedBox(height: 8),
          Text('Key Relationships:', style: _labelStyle),
          const SizedBox(height: 6),
          _formulaBox('I_E  =  I_B  +  I_C'),
          _formulaBox('β_DC  =  I_C / I_B  (typically 100–500 for BC547)'),
          _formulaBox('β_AC  =  ΔI_C / ΔI_B  |  V_CE = constant'),
          _formulaBox('r_in  =  ΔV_BE / ΔI_B  |  V_CE = constant'),
          _formulaBox('r_out =  ΔV_CE / ΔI_C  |  I_B  = constant'),
          const SizedBox(height: 8),
          Text('Characteristic Regions:', style: _labelStyle),
          const SizedBox(height: 6),
          _bulletItem('Active Region: V_CE > 0.2V, V_BE ≈ 0.6–0.7V. I_C ≈ β·I_B. Used for amplification.'),
          _bulletItem('Saturation Region: Both junctions forward biased. V_CE is very small (~0.2V). Used as ON switch.'),
          _bulletItem('Cut-off Region: Both junctions reverse biased. I_C ≈ 0. Used as OFF switch.'),
          const SizedBox(height: 8),
          Text('BC547 Specifications:', style: _labelStyle),
          const SizedBox(height: 4),
          _bulletItem('Type: NPN Silicon BJT'),
          _bulletItem('V_CEO (max): 45V'),
          _bulletItem('I_C (max): 100 mA'),
          _bulletItem('h_FE (β): 110 – 800'),
          _bulletItem('V_BE (forward): ~0.65V'),
        ],
      );

  Widget _formulaBox(String formula) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(5),
          border: Border(left: BorderSide(color: _headerColor, width: 3)),
        ),
        child: Text(formula, style: GoogleFonts.sourceCodePro(fontSize: 11.5, color: _textColor, fontWeight: FontWeight.w600)),
      );

  Widget _procedurePage() => _shell(
        pageNum: 5,
        children: [
          _sectionTitle('5. Procedure'),
          _divider(),
          Text('A. Input Characteristics (I_B vs V_BE at constant V_CE):', style: _labelStyle),
          const SizedBox(height: 6),
          _numberedItem(1, 'Assemble circuit as per diagram. Set V_CE = 2V by adjusting V_CC.'),
          _numberedItem(2, 'Vary V_BB (0 to 2V) in small steps. Record V_BE and I_B at each step.'),
          _numberedItem(3, 'Note: V_BE changes significantly only after ~0.5V (threshold).'),
          _numberedItem(4, 'Repeat the same for V_CE = 5V and V_CE = 10V.'),
          _numberedItem(5, 'Plot I_B (y-axis in µA) vs V_BE (x-axis in V) for all V_CE values.'),
          _divider(),
          Text('B. Output Characteristics (I_C vs V_CE at constant I_B):', style: _labelStyle),
          const SizedBox(height: 6),
          _numberedItem(1, 'Fix I_B = 10 µA by adjusting V_BB with R_B = 100 kΩ.'),
          _numberedItem(2, 'Vary V_CC from 0 to 15V in steps. Record V_CE and I_C.'),
          _numberedItem(3, 'Note transition from saturation region (rising slope) to active region (flat).'),
          _numberedItem(4, 'Repeat for I_B = 20 µA, 30 µA, 40 µA, 50 µA.'),
          _numberedItem(5, 'Plot I_C (y-axis in mA) vs V_CE (x-axis in V) for all I_B values.'),
          _divider(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Precaution: Never exceed I_B > 100 µA. Keep V_CE ≤ 15V to avoid transistor damage.',
                    style: _smallStyle.copyWith(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _inputObservationTable() => _shell(
        pageNum: 6,
        children: [
          _sectionTitle('6. Observations — Input Characteristics'),
          _divider(),
          Text('Table 1: I_B vs V_BE at V_CE = 5V', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTable(
            headers: ['S.No', 'V_BE (V)', 'I_B (µA)'],
            headerColors: [_headerColor, _headerColor, _headerColor],
            rows: [
              ['1', '0.00', '0.00'],
              ['2', '0.10', '0.00'],
              ['3', '0.20', '0.00'],
              ['4', '0.30', '0.00'],
              ['5', '0.40', '0.01'],
              ['6', '0.50', '0.10'],
              ['7', '0.55', '1.20'],
              ['8', '0.60', '5.00'],
              ['9', '0.65', '12.50'],
              ['10', '0.70', '25.00'],
              ['11', '0.75', '42.00'],
              ['12', '0.80', '62.00'],
            ],
          ),
          const SizedBox(height: 10),
          Text('Observation: The transistor begins to conduct significantly after V_BE ≈ 0.5V, exhibiting typical diode-like forward conduction behaviour.', style: _smallStyle),
        ],
      );

  Widget _outputObservationTable() => _shell(
        pageNum: 7,
        children: [
          _sectionTitle('7. Observations — Output Characteristics'),
          _divider(),
          Text('Table 2: I_C vs V_CE at I_B = 20 µA', style: _labelStyle),
          const SizedBox(height: 8),
          _buildTable(
            headers: ['S.No', 'V_CE (V)', 'I_C (mA)'],
            headerColors: [_accentColor, _accentColor, _accentColor],
            rows: [
              ['1',  '0.0',  '0.00'],
              ['2',  '0.1',  '1.80'],
              ['3',  '0.2',  '3.20'],
              ['4',  '0.5',  '4.10'],
              ['5',  '1.0',  '4.60'],
              ['6',  '2.0',  '4.70'],
              ['7',  '3.0',  '4.75'],
              ['8',  '5.0',  '4.80'],
              ['9',  '7.0',  '4.85'],
              ['10', '10.0', '4.90'],
              ['11', '12.0', '4.93'],
              ['12', '14.0', '4.96'],
            ],
          ),
          const SizedBox(height: 10),
          Text('Observation: I_C remains nearly constant in the active region (V_CE > 0.5V), confirming the current-controlled behaviour of the BJT.', style: _smallStyle),
        ],
      );

  Widget _buildTable({
    required List<String> headers,
    required List<Color> headerColors,
    required List<List<String>> rows,
  }) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFBBBBBB), width: 0.8),
      columnWidths: {
        0: const FixedColumnWidth(38),
        for (int i = 1; i < headers.length; i++) i: const FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: headerColors[0]),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            child: Text(h, textAlign: TextAlign.center, style: _tableHeaderStyle),
          )).toList(),
        ),
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return TableRow(
            decoration: BoxDecoration(color: isEven ? const Color(0xFFF5F5F5) : Colors.white),
            children: entry.value.map((cell) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Text(cell, textAlign: TextAlign.center, style: _tableCellStyle),
            )).toList(),
          );
        }),
      ],
    );
  }

  Widget _calculationsPage() => _shell(
        pageNum: 8,
        children: [
          _sectionTitle('8. Calculations'),
          _divider(),
          Text('From the Input Characteristic Curve:', style: _labelStyle),
          const SizedBox(height: 8),
          _formulaBox('ΔV_BE = 0.75 − 0.65 = 0.10 V'),
          _formulaBox('ΔI_B  = 42.0 − 12.5 = 29.5 µA'),
          _formulaBox('r_in  = ΔV_BE / ΔI_B = 0.10 / (29.5×10⁻⁶)'),
          _formulaBox('r_in  ≈  3389 Ω  ≈  3.4 kΩ'),
          _divider(),
          Text('From the Output Characteristic Curve (I_B = 20 µA):', style: _labelStyle),
          const SizedBox(height: 8),
          _formulaBox('ΔV_CE = 14.0 − 7.0 = 7.0 V'),
          _formulaBox('ΔI_C  = 4.96 − 4.85 = 0.11 mA'),
          _formulaBox('r_out = ΔV_CE / ΔI_C = 7.0 / (0.11×10⁻³)'),
          _formulaBox('r_out ≈  63.6 kΩ'),
          _divider(),
          Text('DC Current Gain at Q-point (I_B = 20 µA, V_CE = 5V):', style: _labelStyle),
          const SizedBox(height: 8),
          _formulaBox('β_DC = I_C / I_B = 4.80 mA / 20 µA'),
          _formulaBox('β_DC = 240'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text('β_DC = 240 is within the typical BC547 range of 110–800. ✓', style: _smallStyle.copyWith(color: Colors.green.shade900, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _resultPage() => _shell(
        pageNum: 9,
        children: [
          _sectionTitle('9. Results'),
          _divider(),
          _buildTable(
            headers: ['Parameter', 'Symbol', 'Value'],
            headerColors: [Colors.teal.shade700, Colors.teal.shade700, Colors.teal.shade700],
            rows: [
              ['Input Dynamic Resistance',  'r_in',  '≈ 3.4 kΩ'],
              ['Output Dynamic Resistance', 'r_out', '≈ 63.6 kΩ'],
              ['DC Current Gain (Q-point)', 'β_DC',  '240'],
              ['Threshold Voltage',         'V_BE',  '≈ 0.5 V'],
              ['Active Region Onset',       'V_CE',  '≈ 0.5 V'],
              ['Saturation V_CE',           'V_CE(sat)', '≈ 0.2 V'],
            ],
          ),
          _divider(),
          Text('Graph Observations:', style: _labelStyle),
          const SizedBox(height: 8),
          _bulletItem('Input curve: Exponential I_B rise after V_BE = 0.5V — identical to a forward-biased diode.'),
          _bulletItem('Output curves: Distinct saturation and active regions visible at all I_B levels.'),
          _bulletItem('Active region I_C lines are nearly flat, confirming high output impedance.'),
          _bulletItem('Increasing I_B shifts the output curves upward uniformly, confirming linear β.'),
        ],
      );

  Widget _conclusionPage() => _shell(
        pageNum: 10,
        children: [
          _sectionTitle('10. Conclusion'),
          _divider(),
          Text(
            'The input and output characteristics of the BC547 NPN transistor in Common Emitter configuration were successfully studied and plotted.',
            style: _bodyStyle,
          ),
          const SizedBox(height: 10),
          Text(
            'The experiment confirmed the following:',
            style: _bodyStyle,
          ),
          const SizedBox(height: 6),
          _bulletItem('The CE configuration provides high voltage and current gain simultaneously, making it ideal for amplifier design.'),
          _bulletItem('The input characteristic behaves like a forward-biased p–n junction diode with a threshold of ~0.5V.'),
          _bulletItem('The output characteristics clearly show three operating regions: saturation, active, and cut-off.'),
          _bulletItem('The measured β_DC = 240 is consistent with the BC547 datasheet values (110–800).'),
          _bulletItem('The input impedance (~3.4 kΩ) and output impedance (~63.6 kΩ) match expected CE amplifier characteristics.'),
          _divider(),
          Text('Sources of Error:', style: _labelStyle),
          const SizedBox(height: 6),
          _bulletItem('Meter internal resistance introduces small systematic offset.'),
          _bulletItem('Resistor tolerance (±5%) causes slight deviation in I_B set-point.'),
          _bulletItem('Temperature variation affects V_BE and β during measurement.'),
          _divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 120, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  Text('Faculty Signature', style: _smallStyle),
                ],
              ),
            ],
          ),
        ],
      );

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  Widget _buildNavButton({required IconData icon, required VoidCallback? onTap, required String label}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? _headerColor : const Color(0xFFBBBBBB),
          borderRadius: BorderRadius.circular(8),
          boxShadow: enabled ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == Icons.arrow_back_ios_new_rounded) ...[
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.lato(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ] else ...[
              Text(label, style: GoogleFonts.lato(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(icon, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // ── Info bar ──────────────────────────────────────
        Container(
          color: const Color(0xFF1E2638),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mohit Awasthi  |  125CS0168  |  3rd Sem',
                  style: GoogleFonts.lato(color: const Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${_currentPage + 1} / ${_pages.length}',
                  style: GoogleFonts.lato(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // ── Page content ──────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _pages[i],
          ),
        ),

        // ── Navigation bar ────────────────────────────────
        Container(
          color: const Color(0xFF1E2638),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Previous',
                onTap: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
              ),

              // Page dots
              Row(
                children: List.generate(_pages.length, (i) => GestureDetector(
                  onTap: () => _goTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentPage ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? Colors.amber : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ),

              _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'Next',
                onTap: _currentPage < _pages.length - 1 ? () => _goTo(_currentPage + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(color: const Color(0xFF131927), child: body);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF131927),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Text(
          '2D Lab Record — Experiment 05',
          style: GoogleFonts.merriweather(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white),
            tooltip: 'Go to Cover',
            onPressed: () => _goTo(0),
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white),
            tooltip: 'Go to Last Page',
            onPressed: () => _goTo(_pages.length - 1),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}
