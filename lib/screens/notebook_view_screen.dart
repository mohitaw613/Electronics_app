import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotebookViewScreen extends StatefulWidget {
  final bool embedded;
  const NotebookViewScreen({super.key, this.embedded = false});

  @override
  State<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends State<NotebookViewScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const int _total = 10;

  void _go(int p) {
    if (p < 0 || p >= _total) return;
    setState(() => _page = p);
    _ctrl.animateToPage(p, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // ── colours ──────────────────────────────────────────────────────────────
  static const Color _bg    = Color(0xFFFDFDFD);
  static const Color _navy  = Color(0xFF1A237E);
  static const Color _red   = Color(0xFFC62828);
  static const Color _black = Color(0xFF000000);
  static const Color _grey  = Color(0xFF424242);

  // ── text styles ───────────────────────────────────────────────────────────
  TextStyle get _h1 => GoogleFonts.merriweather(fontSize: 15, fontWeight: FontWeight.bold, color: _navy);
  TextStyle get _h2 => GoogleFonts.merriweather(fontSize: 13, fontWeight: FontWeight.bold, color: _navy);
  TextStyle get _body => GoogleFonts.lato(fontSize: 13, color: _black, height: 1.6);
  TextStyle get _small => GoogleFonts.lato(fontSize: 11, color: _grey);
  TextStyle get _label => GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700, color: _black);

  // ── helpers ───────────────────────────────────────────────────────────────
  Widget _title(String t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(t, style: _h1),
          const SizedBox(height: 4),
          Container(height: 2, width: 50, color: _red),
          const SizedBox(height: 10),
        ],
      );

  Widget _sub(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(t, style: _h2),
      );

  Widget _p(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: _body),
      );

  Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: _body.copyWith(color: _red)),
            Expanded(child: Text(t, style: _body)),
          ],
        ),
      );

  Widget _box(String label, String val) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _navy.withAlpha(60)),
        ),
        child: Row(
          children: [
            Text('$label:  ', style: _label),
            Expanded(child: Text(val, style: _body.copyWith(fontFamily: 'monospace'))),
          ],
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: Color(0xFFBBDEFB), thickness: 1),
      );

  Widget _footer(int num) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFBBDEFB), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BJT Common Emitter — EC Lab', style: _small),
            Text('Page $num of $_total', style: _small),
          ],
        ),
      );

  // ── page wrapper ─────────────────────────────────────────────────────────
  Widget _wrap(int num, List<Widget> children) => Container(
        color: _bg,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _footer(num),
            ),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _coverPage() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.menu_book, color: Colors.amber, size: 54),
                const SizedBox(height: 16),
                Text('LAB RECORD', style: GoogleFonts.merriweather(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text('Electronics Laboratory', style: GoogleFonts.lato(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 20),
                _coverRow('Experiment', '05'),
                _coverRow('Title', 'BJT Common Emitter\nCharacteristics'),
                _coverRow('Component', 'BC547 NPN Transistor'),
                _coverRow('Institution', 'NIT Rourkela'),
                _coverRow('Department', 'Electronics & Comm.'),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 16),
                Text('Page 1 of $_total', style: GoogleFonts.lato(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ),
      );

  Widget _coverRow(String label, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.lato(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(val, style: GoogleFonts.lato(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _page2() => _wrap(2, [
        _title('1. Objective'),
        _p('To study the input and output characteristics of an NPN BJT (BC547) in Common Emitter (CE) configuration and determine:'),
        _bullet('Input curve: I_B vs V_BE at constant V_CE'),
        _bullet('Output curve: I_C vs V_CE at constant I_B'),
        _bullet('DC current gain  β_DC = I_C / I_B'),
        _bullet('AC current gain  β_AC = ΔI_C / ΔI_B'),
        _bullet('Input resistance  r_in = ΔV_BE / ΔI_B'),
        _bullet('Output resistance  r_out = ΔV_CE / ΔI_C'),
      ]);

  Widget _page3() => _wrap(3, [
        _title('2. Apparatus Required'),
        _bullet('NPN Transistor: BC547'),
        _bullet('DC Power Supplies: 0–5 V (input side), 0–15 V (output side)'),
        _bullet('Digital Multimeters × 2  (measure V_BE, I_B, V_CE, I_C)'),
        _bullet('Resistors: R_B = 100 kΩ,  R_C = 1 kΩ'),
        _bullet('Breadboard and connecting wires'),
        _bullet('Graph paper / Lab notebook'),
        _divider(),
        _title('3. Circuit Connections'),
        _p('CE Configuration — Base is input terminal, Collector is output terminal, Emitter is common to both.'),
        _sub('BC547 Pin Assignment (TO-92 package, flat face towards you)'),
        _bullet('Pin 1 (left)   → Collector (C)'),
        _bullet('Pin 2 (centre) → Base (B)'),
        _bullet('Pin 3 (right)  → Emitter (E)'),
        _sub('Connections'),
        _bullet('V_BB → R_B (100 kΩ) → Base'),
        _bullet('Collector → R_C (1 kΩ) → V_CC'),
        _bullet('Emitter → GND'),
      ]);

  Widget _page4() => _wrap(4, [
        _title('4. Theory'),
        _p('A BJT (Bipolar Junction Transistor) is a current-controlled device. In CE configuration the emitter is common to both input and output loops.'),
        _sub('Operating Regions'),
        _bullet('Active region  — normal amplification'),
        _bullet('Saturation region  — both junctions forward biased'),
        _bullet('Cut-off region  — both junctions reverse biased'),
        _sub('BC547 Key Specifications'),
        _box('V_CE(max)', '45 V'),
        _box('I_C(max)', '100 mA'),
        _box('β (hFE)', '110 – 800'),
        _box('P_D(max)', '500 mW'),
        _sub('Key Formulas'),
        _box('β_DC', 'I_C / I_B'),
        _box('β_AC', 'ΔI_C / ΔI_B  (at const V_CE)'),
        _box('r_in', 'ΔV_BE / ΔI_B  (at const V_CE)'),
        _box('r_out', 'ΔV_CE / ΔI_C  (at const I_B)'),
      ]);

  Widget _page5() => _wrap(5, [
        _title('5. Procedure'),
        _sub('A. Input Characteristics  (I_B vs V_BE)'),
        _bullet('Keep V_CE = 5 V constant.'),
        _bullet('Vary V_BB from 0 V; note I_B for each V_BE (0 to 0.7 V steps).'),
        _bullet('Repeat if needed for another V_CE.'),
        _bullet('Plot I_B (µA) vs V_BE (V).'),
        _divider(),
        _sub('B. Output Characteristics  (I_C vs V_CE)'),
        _bullet('Keep I_B = 20 µA constant.'),
        _bullet('Vary V_CC; note I_C for each V_CE (0 to 12 V steps).'),
        _bullet('Repeat for I_B = 40 µA, 60 µA.'),
        _bullet('Plot I_C (mA) vs V_CE (V).'),
        _divider(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8), border: Border.all(color: _red)),
          child: Text('⚠  Warning: Do not exceed I_C = 100 mA or V_CE = 45 V. Always increase voltage slowly.', style: _body.copyWith(color: _red, fontSize: 12)),
        ),
      ]);

  Widget _page6() => _wrap(6, [
        _title('6. Observation Table — Input Characteristics'),
        _p('Constant: V_CE = 5 V'),
        const SizedBox(height: 8),
        _obsTable1(),
      ]);

  Widget _obsTable1() {
    final rows = [
      ['0.00', '0'],
      ['0.10', '0'],
      ['0.20', '0'],
      ['0.30', '0'],
      ['0.40', '1'],
      ['0.50', '5'],
      ['0.55', '10'],
      ['0.60', '20'],
      ['0.63', '30'],
      ['0.65', '40'],
      ['0.67', '50'],
      ['0.70', '60'],
    ];
    return _table(
      headers: const ['V_BE (V)', 'I_B (µA)'],
      rows: rows,
    );
  }

  Widget _page7() => _wrap(7, [
        _title('7. Observation Table — Output Characteristics'),
        _p('Constant: I_B = 20 µA'),
        const SizedBox(height: 8),
        _obsTable2(),
      ]);

  Widget _obsTable2() {
    final rows = [
      ['0.0', '0.00'],
      ['0.5', '2.00'],
      ['1.0', '3.80'],
      ['1.5', '4.20'],
      ['2.0', '4.40'],
      ['3.0', '4.50'],
      ['4.0', '4.52'],
      ['5.0', '4.54'],
      ['6.0', '4.56'],
      ['8.0', '4.60'],
      ['10.0', '4.64'],
      ['12.0', '4.68'],
    ];
    return _table(
      headers: const ['V_CE (V)', 'I_C (mA)'],
      rows: rows,
    );
  }

  Widget _table({required List<String> headers, required List<List<String>> rows}) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF90CAF9), width: 1),
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF1A237E)),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Text(h, style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          )).toList(),
        ),
        ...rows.asMap().entries.map((e) => TableRow(
          decoration: BoxDecoration(color: e.key.isEven ? Colors.white : const Color(0xFFE8EAF6)),
          children: e.value.map((cell) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            child: Text(cell, style: GoogleFonts.lato(fontSize: 12, color: _black), textAlign: TextAlign.center),
          )).toList(),
        )),
      ],
    );
  }

  Widget _page8() => _wrap(8, [
        _title('8. Calculations'),
        _sub('DC Current Gain (β_DC)'),
        _box('β_DC', 'I_C / I_B  =  4.54 mA / 20 µA  =  227'),
        _sub('Input Dynamic Resistance (r_in)'),
        _box('r_in', 'ΔV_BE / ΔI_B  =  (0.65 − 0.60) V / (40 − 20) µA  =  2.5 kΩ'),
        _sub('Output Dynamic Resistance (r_out)'),
        _box('r_out', 'ΔV_CE / ΔI_C  =  (10 − 5) V / (4.64 − 4.54) mA  =  50 kΩ'),
        _divider(),
        _p('Note: All values are calculated from the observed data. Actual values may differ based on your readings.'),
      ]);

  Widget _page9() => _wrap(9, [
        _title('9. Results'),
        const SizedBox(height: 8),
        _table(
          headers: const ['Parameter', 'Value'],
          rows: const [
            ['β_DC (DC gain)', '227'],
            ['β_AC (AC gain)', '~220'],
            ['r_in (input resistance)', '2.5 kΩ'],
            ['r_out (output resistance)', '50 kΩ'],
            ['V_BE (threshold)', '~0.6 V'],
            ['I_C (at V_CE=5V, I_B=20µA)', '4.54 mA'],
          ],
        ),
      ]);

  Widget _page10() => _wrap(10, [
        _title('10. Conclusion'),
        _p('The input and output characteristics of the BC547 NPN transistor in CE configuration were successfully studied.'),
        _bullet('The transistor showed clear cut-off, active, and saturation regions.'),
        _bullet('DC current gain (β_DC) was found to be approximately 227.'),
        _bullet('Input dynamic resistance r_in ≈ 2.5 kΩ.'),
        _bullet('Output dynamic resistance r_out ≈ 50 kΩ.'),
        _divider(),
        _sub('Sources of Error'),
        _bullet('Contact resistance in breadboard connections.'),
        _bullet('Multimeter accuracy limitations.'),
        _bullet('Heating of transistor during prolonged measurements.'),
        _divider(),
        _sub('Faculty Signature'),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 120, height: 1, color: Colors.black54),
              const SizedBox(height: 4),
              Text('Student Signature', style: _small),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(width: 120, height: 1, color: Colors.black54),
              const SizedBox(height: 4),
              Text('Faculty Signature', style: _small),
            ]),
          ],
        ),
      ]);

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  List<Widget> get _pages => [
        _coverPage(), _page2(), _page3(), _page4(), _page5(),
        _page6(), _page7(), _page8(), _page9(), _page10(),
      ];

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // ── page area ───────────────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _total,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _pages[i],
          ),
        ),
        // ── nav bar ─────────────────────────────────────────────────────
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Previous
              TextButton.icon(
                onPressed: _page > 0 ? () => _go(_page - 1) : null,
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                label: const Text('Prev', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: TextButton.styleFrom(
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
              // dots
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_total, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _page == i ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _page == i ? Colors.amber : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ),
              ),
              // Next
              TextButton.icon(
                onPressed: _page < _total - 1 ? () => _go(_page + 1) : null,
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                label: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: TextButton.styleFrom(
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('Lab Record — Exp 05  (${_page + 1}/$_total)',
            style: GoogleFonts.merriweather(fontSize: 13, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.first_page), onPressed: () => _go(0), tooltip: 'First page'),
          IconButton(icon: const Icon(Icons.last_page), onPressed: () => _go(_total - 1), tooltip: 'Last page'),
        ],
      ),
      body: body,
    );
  }
}
