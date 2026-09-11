import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const BJTWorkbenchApp());
}

// ============================================================================
// COLORS
// ============================================================================

const Color kBg = Color(0xFF020A10);
const Color kPanel = Color(0xFF04151B);
const Color kPanel2 = Color(0xFF071820);

const Color kCyan = Color(0xFF18DDF5);
const Color kCyanDim = Color(0xFF0D6875);
const Color kCyanDark = Color(0xFF0B3942);

const Color kGreen = Color(0xFF65F48A);
const Color kRed = Color(0xFFFF7065);

const Color kWhite = Color(0xFFE7F1F3);
const Color kMuted = Color(0xFF91A6AC);

// ============================================================================
// APP
// ============================================================================

class BJTWorkbenchApp extends StatelessWidget {
  const BJTWorkbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BJT CE Workbench',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'monospace',
        colorScheme: ColorScheme.fromSeed(
          seedColor: kCyan,
          brightness: Brightness.dark,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: kCyan,
          inactiveTrackColor: Color(0xFF123B43),
          thumbColor: kGreen,
          overlayColor: Color(0x2218DDF5),
          trackHeight: 5,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF78D1DF),
            foregroundColor: const Color(0xFF062229),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
      home: const BJTWorkbench(),
    );
  }
}

// ============================================================================
// LAYOUT MODE
// ============================================================================

enum LayoutMode {
  auto,
  desktop,
  mobile,
}

// ============================================================================
// MAIN WORKBENCH
// ============================================================================

class BJTWorkbench extends StatefulWidget {
  const BJTWorkbench({super.key});

  @override
  State<BJTWorkbench> createState() => _BJTWorkbenchState();
}

class _BJTWorkbenchState extends State<BJTWorkbench> {
  // ==========================================================================
  // LAYOUT
  // ==========================================================================

  LayoutMode layoutMode = LayoutMode.auto;

  // ==========================================================================
  // PARAMETERS
  // ==========================================================================

  double rb = 120000;
  double rc = 2200;
  double temperature = 25.4;
  double vbe = 0.725;
  double vcc = 12.0;

  bool active = true;
  bool grid = true;
  bool calibrated = true;

  // ==========================================================================
  // CONSOLE
  // ==========================================================================

  final List<String> console = [
    '> ready_sweeps VBE 0.6:0.01:0.75V',
    '> model=2N3904',
    '> calibrated=true',
  ];

  // ==========================================================================
  // BJT CALCULATIONS
  // ==========================================================================

  double get beta => 125.0;

  double get thermalVbe {
    return 0.65 - ((temperature - 25.0) * 0.002);
  }

  double get ib {
    const referenceVbe = 0.725;
    const referenceIb = 15.4;

    if (vbe <= thermalVbe) {
      return 0.0;
    }

    final exponent = (vbe - referenceVbe) / 0.026;

    final temperatureFactor = math.exp(-(temperature - 25.0) * 0.006);

    final resistanceFactor = 120000.0 / rb;

    return referenceIb *
        math.exp(exponent) *
        resistanceFactor *
        temperatureFactor;
  }

  double get ic {
    final transistorCurrent = ib * beta / 1000.0;

    final resistorLimit = vcc / rc * 1000.0;

    return math.min(
      transistorCurrent,
      resistorLimit,
    );
  }

  double get vce {
    return math.max(
      0.08,
      vcc - ((ic / 1000.0) * rc),
    );
  }

  double get gm {
    if (ic <= 0) {
      return 0.0;
    }

    return (ic / 1000.0) / 0.02585;
  }

  double get rpi {
    if (gm <= 0) {
      return double.infinity;
    }

    return beta / gm;
  }

  double get av {
    if (gm <= 0) {
      return 0.0;
    }

    return -(gm * rc);
  }

  // ==========================================================================
  // FORMATTING
  // ==========================================================================

  String formatResistance(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} MΩ';
    }

    if (value >= 1000) {
      final k = value / 1000.0;

      if (k == k.roundToDouble()) {
        return '${k.round()} kΩ';
      }

      return '${k.toStringAsFixed(1)} kΩ';
    }

    return '${value.round()} Ω';
  }

  String formatRpi() {
    if (rpi.isInfinite) {
      return '∞';
    }

    return '${(rpi / 1000.0).toStringAsFixed(2)} kΩ';
  }

  // ==========================================================================
  // SWEEP
  // ==========================================================================

  void runSweep() {
    setState(() {
      calibrated = true;

      console
        ..clear()
        ..add(
          '> set_sweep VBE 0.6:0.01:0.75V',
        )
        ..add(
          '> sweeping...',
        )
        ..add(
          'VBE=${vbe.toStringAsFixed(3)}V '
          'VCE=${vce.toStringAsFixed(2)}V '
          'IC=${ic.toStringAsFixed(2)}mA',
        )
        ..add(
          '[[CALIBRATED] [TRUE]]',
        );
    });
  }

  // ==========================================================================
  // RESET
  // ==========================================================================

  void resetValues() {
    setState(() {
      rb = 120000;
      rc = 2200;
      temperature = 25.4;
      vbe = 0.725;
      vcc = 12.0;
      active = true;
      grid = true;
      calibrated = true;

      console
        ..clear()
        ..add(
          '> ready_sweeps VBE 0.6:0.01:0.75V',
        )
        ..add(
          '> model=2N3904',
        )
        ..add(
          '> calibrated=true',
        );
    });
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool autoMobile = constraints.maxWidth < 900;

            final bool useMobile = layoutMode == LayoutMode.mobile ||
                (layoutMode == LayoutMode.auto && autoMobile);

            if (useMobile) {
              return _buildMobile();
            }

            return _buildDesktop();
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // DESKTOP LAYOUT
  // ==========================================================================

  Widget _buildDesktop() {
    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 370,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    4,
                    4,
                    10,
                  ),
                  child: _buildDesktopControls(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    4,
                    4,
                    8,
                    10,
                  ),
                  child: _buildDesktopMain(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DESKTOP HEADER
  // ==========================================================================

  Widget _buildDesktopHeader() {
    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(
        8,
        7,
        8,
        5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(
          color: kCyan,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3318DDF5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'BJT CE WORKBENCH',
            style: TextStyle(
              color: kCyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 18),
          _desktopMetric(
            'VBE',
            '${vbe.toStringAsFixed(3)}V',
          ),
          _desktopMetric(
            'IB',
            '${ib.toStringAsFixed(1)}µA',
          ),
          _desktopMetric(
            'IC',
            '${ic.toStringAsFixed(2)}mA',
          ),
          _desktopMetric(
            'VCE',
            '${vce.toStringAsFixed(2)}V',
          ),
          _desktopMetric(
            'gm',
            '${(gm * 1000).toStringAsFixed(1)}mS',
          ),
          _desktopMetric(
            'rπ',
            formatRpi(),
          ),
          _desktopMetric(
            'Av',
            av.toStringAsFixed(0),
          ),
          const Spacer(),
          _layoutMenu(),
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Reset',
            onPressed: resetValues,
            icon: const Icon(
              Icons.refresh,
              color: kCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopMetric(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: kMuted,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: kGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DESKTOP CONTROLS
  // ==========================================================================

  Widget _buildDesktopControls() {
    return _panel(
      'PARAMETER CONTROL',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _desktopKnob(
            title: 'BASE RESISTANCE (RB)',
            value: rb,
            min: 10000,
            max: 250000,
            divisions: 240,
            step: '±1kΩ',
            display: formatResistance(rb),
            onChanged: (value) {
              setState(() {
                rb = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _desktopKnob(
            title: 'COLLECTOR RESISTANCE (RC)',
            value: rc,
            min: 500,
            max: 5000,
            divisions: 45,
            step: '±100Ω',
            display: formatResistance(rc),
            onChanged: (value) {
              setState(() {
                rc = value;
              });
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'JUNCTION TEMPERATURE',
            style: TextStyle(
              color: kWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              color: kGreen,
              fontSize: 13,
            ),
          ),
          Slider(
            value: temperature,
            min: 0,
            max: 100,
            onChanged: (value) {
              setState(() {
                temperature = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _actionButton(
            text: 'RUN VBE SWEEP',
            icon: Icons.play_arrow,
            onPressed: runSweep,
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            text: 'RESET PARAMETERS',
            icon: Icons.refresh,
            onPressed: resetValues,
          ),
        ],
      ),
    );
  }

  Widget _desktopKnob({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String step,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    final double progress =
        ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kWhite,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 125,
              height: 125,
              child: CustomPaint(
                painter: KnobPainter(
                  progress: progress,
                ),
                child: Center(
                  child: Text(
                    display,
                    style: const TextStyle(
                      color: kCyan,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'STEP: $step',
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 11,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // DESKTOP MAIN
  // ==========================================================================

  Widget _buildDesktopMain() {
    return Column(
      children: [
        _buildGraphPanel(
          height: 450,
          mobile: false,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  _buildDataMatrix(
                    mobile: false,
                  ),
                  const SizedBox(height: 10),
                  _buildConsole(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDataMatrix(
                    mobile: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildConsole(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // MOBILE LAYOUT
  // ==========================================================================

  Widget _buildMobile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMobileRail(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              10,
              8,
              10,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMobileHeader(),
                const SizedBox(height: 10),
                _buildGraphPanel(
                  height: 425,
                  mobile: true,
                ),
                const SizedBox(height: 10),
                _buildDataMatrix(
                  mobile: true,
                ),
                const SizedBox(height: 10),
                _buildMobileControls(),
                const SizedBox(height: 10),
                _buildMobileConsole(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // MOBILE RAIL
  // ==========================================================================

  Widget _buildMobileRail() {
    return Container(
      width: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF061119),
        border: Border(
          right: BorderSide(
            color: Color(0xFF123F49),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          _railButton(
            Icons.dashboard,
            selected: true,
          ),
          _railButton(
            Icons.analytics_outlined,
          ),
          _railButton(
            Icons.build_outlined,
          ),
          const Spacer(),
          _railButton(
            Icons.settings_outlined,
            onPressed: _showSettings,
          ),
          _railButton(
            Icons.description_outlined,
          ),
          _railButton(
            Icons.help_outline,
          ),
          _railButton(
            Icons.tune,
            onPressed: _showSettings,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _railButton(
    IconData icon, {
    bool selected = false,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF103A44) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: selected
            ? Border.all(
                color: kCyanDim,
              )
            : null,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
          color: selected ? kCyan : kMuted,
        ),
      ),
    );
  }

  // ==========================================================================
  // MOBILE HEADER
  // ==========================================================================

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(
          color: kCyanDim,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2218DDF5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 13,
              runSpacing: 5,
              children: [
                _mobileMetric(
                  'VBE',
                  '${vbe.toStringAsFixed(3)}V',
                ),
                _mobileMetric(
                  'IB',
                  '${ib.toStringAsFixed(1)}µA',
                ),
                _mobileMetric(
                  'IC',
                  '${ic.toStringAsFixed(2)}mA',
                ),
                _mobileMetric(
                  'VCE',
                  '${vce.toStringAsFixed(2)}V',
                ),
                _mobileMetric(
                  'GM',
                  '${(gm * 1000).toStringAsFixed(1)}mS',
                ),
                _mobileMetric(
                  'Rπ',
                  formatRpi(),
                ),
                _mobileMetric(
                  'Av',
                  av.toStringAsFixed(0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    active = !active;
                  });
                },
                child: Container(
                  width: 94,
                  height: 62,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF68E979)
                        : const Color(0xFF475558),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    active ? 'ACTIVE' : 'PAUSED',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _smallIconButton(
                    Icons.autorenew,
                    onPressed: _showSettings,
                  ),
                  _smallIconButton(
                    Icons.refresh,
                    onPressed: resetValues,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileMetric(
    String label,
    String value,
  ) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: kWhite,
              fontSize: 13,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: kGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIconButton(
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 15,
          color: kCyan,
        ),
      ),
    );
  }

  // ==========================================================================
  // GRAPH
  // ==========================================================================

  Widget _buildGraphPanel({
    required double height,
    required bool mobile,
  }) {
    return _panel(
      mobile
          ? 'OUTPUT CHARACTERISTIC: IC vs VCE'
          : 'OUTPUT CHARACTERISTIC CURVE: IC vs VCE (COMMON EMITTER)',
      Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(
                qVce: vce,
                qIc: ic,
                vcc: vcc,
                rc: rc,
                showGrid: grid,
                mobile: mobile,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const Divider(
            color: kCyanDark,
            height: 1,
          ),
          if (mobile)
            _buildMobileGraphControls()
          else
            _buildDesktopGraphControls(),
        ],
      ),
    );
  }

  Widget _buildDesktopGraphControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        5,
        8,
        3,
      ),
      child: Column(
        children: [
          _graphSlider(
            label: 'VBE',
            value: vbe,
            min: 0.6,
            max: 0.75,
            divisions: 150,
            display: '${vbe.toStringAsFixed(4)}V',
            onChanged: (value) {
              setState(() {
                vbe = value;
              });
            },
          ),
          _graphSlider(
            label: 'VCC',
            value: vcc,
            min: 5,
            max: 18,
            divisions: 130,
            display: '${vcc.toStringAsFixed(1)}V',
            onChanged: (value) {
              setState(() {
                vcc = value;
              });
            },
          ),
          Row(
            children: [
              const Text(
                'GRID',
                style: TextStyle(
                  color: kWhite,
                ),
              ),
              Switch(
                value: grid,
                onChanged: (value) {
                  setState(() {
                    grid = value;
                  });
                },
              ),
              const Spacer(),
              Text(
                'Q: ${ic.toStringAsFixed(2)}mA / '
                '${vce.toStringAsFixed(2)}V',
                style: const TextStyle(
                  color: kGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGraphControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: Row(
        children: [
          const Text(
            'GRID',
            style: TextStyle(
              color: kWhite,
              fontSize: 12,
            ),
          ),
          Switch(
            value: grid,
            onChanged: (value) {
              setState(() {
                grid = value;
              });
            },
          ),
          const Spacer(),
          Text(
            'Q ${ic.toStringAsFixed(2)}mA / '
            '${vce.toStringAsFixed(2)}V',
            style: const TextStyle(
              color: kGreen,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _graphSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              color: kWhite,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 62,
          child: Text(
            display,
            style: const TextStyle(
              color: kGreen,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // MOBILE CONTROLS
  // ==========================================================================

  Widget _buildMobileControls() {
    return _panel(
      'PARAMETER CONTROL',
      Column(
        children: [
          _mobileParameter(
            symbol: 'RB',
            title: 'BASE RESISTANCE',
            value: rb,
            min: 10000,
            max: 250000,
            divisions: 240,
            display: formatResistance(rb),
            onChanged: (value) {
              setState(() {
                rb = value;
              });
            },
          ),
          const SizedBox(height: 10),
          _mobileParameter(
            symbol: 'RC',
            title: 'COLLECTOR RESISTANCE',
            value: rc,
            min: 500,
            max: 5000,
            divisions: 45,
            display: formatResistance(rc),
            onChanged: (value) {
              setState(() {
                rc = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 70,
                child: CustomPaint(
                  painter: TransistorPainter(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'JUNCTION TEMPERATURE',
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${temperature.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            color: kGreen,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: temperature,
                      min: 0,
                      max: 100,
                      onChanged: (value) {
                        setState(() {
                          temperature = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: runSweep,
              icon: const Icon(
                Icons.play_arrow,
              ),
              label: const Text(
                'RUN VBE SWEEP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileParameter({
    required String symbol,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 70,
          child: CustomPaint(
            painter: TransistorPainter(),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$symbol  ($title)',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions,
                      onChanged: onChanged,
                    ),
                  ),
                  Container(
                    width: 112,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kPanel2,
                      border: Border.all(
                        color: kCyanDim,
                      ),
                      borderRadius: BorderRadius.circular(
                        5,
                      ),
                    ),
                    child: Text(
                      display,
                      style: const TextStyle(
                        color: kGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DATA MATRIX
  // ==========================================================================

  Widget _buildDataMatrix({
    required bool mobile,
  }) {
    final List<List<String>> rows = [];

    for (int index = 0; index < 7; index++) {
      final double testVbe =
          (vbe - 0.018 + index * 0.006).clamp(0.6, 0.75).toDouble();

      final double testIb = testVbe <= thermalVbe
          ? 0.0
          : 15.4 *
              math.exp(
                (testVbe - 0.725) / 0.026,
              ) *
              (120000.0 / rb) *
              math.exp(
                -(temperature - 25.0) * 0.006,
              );

      final double testIc = math.min(
        testIb * beta / 1000.0,
        vcc / rc * 1000.0,
      );

      final double testVce = math.max(
        0.08,
        vcc - (testIc / 1000.0) * rc,
      );

      final double testGm = testIc <= 0 ? 0.0 : (testIc / 1000.0) / 0.02585;

      final double testRpi = testGm <= 0 ? double.infinity : beta / testGm;

      final double testAv = -(testGm * rc);

      rows.add([
        testVbe.toStringAsFixed(3),
        testIb.toStringAsFixed(1),
        testIc.toStringAsFixed(2),
        testVce.toStringAsFixed(2),
        (testGm * 1000).toStringAsFixed(1),
        testRpi.isInfinite ? '∞' : (testRpi / 1000).toStringAsFixed(2),
        testAv.toStringAsFixed(0),
      ]);
    }

    const headers = [
      'VBE',
      'IB',
      'IC',
      'VCE',
      'gm',
      'rπ',
      'Av',
    ];

    return _panel(
      'DATA STREAM MATRIX',
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: mobile ? 43 : 36,
          dataRowMinHeight: mobile ? 32 : 29,
          dataRowMaxHeight: mobile ? 36 : 33,
          columnSpacing: mobile ? 20 : 17,
          horizontalMargin: 3,
          columns: headers.map(
            (header) {
              return DataColumn(
                label: Text(
                  header,
                  style: TextStyle(
                    color: mobile ? kGreen : kWhite,
                    fontSize: mobile ? 11 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ).toList(),
          rows: rows.map(
            (row) {
              return DataRow(
                cells: row.map(
                  (value) {
                    return DataCell(
                      Text(
                        value,
                        style: TextStyle(
                          color: kGreen,
                          fontSize: mobile ? 11 : 10,
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ==========================================================================
  // DESKTOP CONSOLE
  // ==========================================================================

  Widget _buildConsole() {
    // IMPORTANT: this console is inside a vertical SingleChildScrollView on
    // desktop. Therefore it must have a finite height and must not use a
    // Spacer/Expanded that asks for infinite remaining height.
    return _panel(
      'CLI CONSOLE',
      SizedBox(
        height: 240,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF01090D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: kCyanDim,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: console.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        console[index],
                        style: const TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '> ready_sweeps VBE 0.6:0.01:0.75V',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kGreen,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Run sweep',
                      onPressed: runSweep,
                      icon: const Icon(
                        Icons.play_arrow,
                        color: kCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MOBILE CONSOLE
  // ==========================================================================

  Widget _buildMobileConsole() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF031017),
        border: Border.all(
          color: kCyanDim,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              console.isEmpty
                  ? '> ready_sweeps VBE 0.6:0.01:0.75V'
                  : console.last,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kGreen,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Run sweep',
            onPressed: runSweep,
            icon: const Icon(
              Icons.play_arrow,
              color: kCyan,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PANEL
  // ==========================================================================

  Widget _panel(
    String title,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPanel,
        border: Border.all(
          color: kCyanDim,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: kCyanDark,
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: kCyan,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: .3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUTTONS
  // ==========================================================================

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 43,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: kWhite,
          side: const BorderSide(
            color: kCyanDim,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  // ==========================================================================
  // LAYOUT MENU
  // ==========================================================================

  Widget _layoutMenu() {
    return PopupMenuButton<LayoutMode>(
      tooltip: 'Layout mode',
      color: kPanel2,
      onSelected: (mode) {
        setState(() {
          layoutMode = mode;
        });
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: LayoutMode.auto,
            child: Row(
              children: [
                Icon(
                  Icons.autorenew,
                  color: kCyan,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('AUTO'),
              ],
            ),
          ),
          PopupMenuItem(
            value: LayoutMode.desktop,
            child: Row(
              children: [
                Icon(
                  Icons.desktop_windows,
                  color: kCyan,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('DESKTOP'),
              ],
            ),
          ),
          PopupMenuItem(
            value: LayoutMode.mobile,
            child: Row(
              children: [
                Icon(
                  Icons.smartphone,
                  color: kCyan,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('MOBILE'),
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: kCyanDim,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              layoutMode == LayoutMode.mobile
                  ? Icons.smartphone
                  : layoutMode == LayoutMode.desktop
                      ? Icons.desktop_windows
                      : Icons.autorenew,
              size: 15,
              color: kCyan,
            ),
            const SizedBox(width: 5),
            Text(
              layoutMode.name.toUpperCase(),
              style: const TextStyle(
                color: kWhite,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SETTINGS
  // ==========================================================================

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LAYOUT MODE',
                  style: TextStyle(
                    color: kCyan,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _layoutOption(
                  sheetContext,
                  'AUTO',
                  Icons.autorenew,
                  LayoutMode.auto,
                ),
                _layoutOption(
                  sheetContext,
                  'DESKTOP',
                  Icons.desktop_windows,
                  LayoutMode.desktop,
                ),
                _layoutOption(
                  sheetContext,
                  'MOBILE',
                  Icons.smartphone,
                  LayoutMode.mobile,
                ),
                const SizedBox(height: 8),
                _secondaryButton(
                  text: 'RESET VALUES',
                  icon: Icons.refresh,
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    resetValues();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _layoutOption(
    BuildContext sheetContext,
    String title,
    IconData icon,
    LayoutMode mode,
  ) {
    final bool selected = layoutMode == mode;

    return ListTile(
      onTap: () {
        setState(() {
          layoutMode = mode;
        });

        Navigator.pop(
          sheetContext,
        );
      },
      leading: Icon(
        icon,
        color: selected ? kCyan : kMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? kCyan : kWhite,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check,
              color: kGreen,
            )
          : null,
    );
  }

  // ==========================================================================
  // FOOTER
  // ==========================================================================

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(
          Icons.flutter_dash,
          color: kCyan,
          size: 30,
        ),
        const SizedBox(width: 5),
        const Text(
          'build with\nFLUTTER',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: kMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// KNOB PAINTER
// ============================================================================

class KnobPainter extends CustomPainter {
  final double progress;

  KnobPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = size.center(Offset.zero);

    final double radius = math.min(
          size.width,
          size.height,
        ) *
        0.37;

    final Paint outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..color = const Color(0xFF063641);

    final Paint active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = kCyan;

    canvas.drawCircle(
      center,
      radius,
      outer,
    );

    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    const double startAngle = -2.35;

    canvas.drawArc(
      rect,
      startAngle,
      math.pi * 1.7 * progress,
      false,
      active,
    );

    final double angle = startAngle + math.pi * 1.7 * progress;

    final Offset indicator = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    canvas.drawCircle(
      indicator,
      4,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      radius * 0.70,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kCyanDim,
    );
  }

  @override
  bool shouldRepaint(
    covariant KnobPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// TRANSISTOR ICON
// ============================================================================

class TransistorPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint = Paint()
      ..color = const Color(
        0xFFB8C8CC,
      )
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double cx = size.width * 0.48;

    final double cy = size.height * 0.50;

    // Base
    canvas.drawLine(
      Offset(
        cx - 16,
        cy,
      ),
      Offset(
        cx,
        cy,
      ),
      paint,
    );

    // Body
    canvas.drawLine(
      Offset(
        cx,
        cy - 17,
      ),
      Offset(
        cx,
        cy + 17,
      ),
      paint,
    );

    // Collector
    canvas.drawLine(
      Offset(
        cx,
        cy - 9,
      ),
      Offset(
        cx + 17,
        cy - 27,
      ),
      paint,
    );

    // Emitter
    canvas.drawLine(
      Offset(
        cx,
        cy + 9,
      ),
      Offset(
        cx + 17,
        cy + 27,
      ),
      paint,
    );

    // Emitter arrow
    final Path arrow = Path()
      ..moveTo(
        cx + 9,
        cy + 20,
      )
      ..lineTo(
        cx + 17,
        cy + 27,
      )
      ..lineTo(
        cx + 9,
        cy + 27,
      );

    canvas.drawPath(
      arrow,
      paint,
    );

    // Small resistor
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          cx - 16,
          cy - 29,
        ),
        width: 4,
        height: 12,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        cx - 16,
        cy - 35,
      ),
      Offset(
        cx - 16,
        cy - 29,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        cx + 17,
        cy + 27,
      ),
      Offset(
        cx + 17,
        cy + 34,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant TransistorPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// CHART PAINTER
// ============================================================================

class ChartPainter extends CustomPainter {
  final double qVce;
  final double qIc;
  final double vcc;
  final double rc;
  final bool showGrid;
  final bool mobile;

  ChartPainter({
    required this.qVce,
    required this.qIc,
    required this.vcc,
    required this.rc,
    required this.showGrid,
    required this.mobile,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width < 100 || size.height < 100) {
      return;
    }

    // ------------------------------------------------------------------------
    // PLOT
    // ------------------------------------------------------------------------

    final double left = mobile ? 45.0 : 60.0;

    final double top = 18.0;

    final double right = mobile ? 20.0 : 28.0;

    final double bottom = mobile ? 42.0 : 48.0;

    final Rect plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    // ------------------------------------------------------------------------
    // PAINTS
    // ------------------------------------------------------------------------

    final Paint gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = const Color(
        0x334AB8C6,
      );

    final Paint axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(
        0xFFB8D2D7,
      );

    final Paint curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = mobile ? 2.1 : 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF42F28A,
      );

    final Paint loadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = mobile ? 2.7 : 3.0
      ..strokeCap = StrokeCap.round
      ..color = kRed;

    // ------------------------------------------------------------------------
    // GRID
    // ------------------------------------------------------------------------

    if (showGrid) {
      for (int x = 0; x <= 12; x++) {
        final double px = plot.left + plot.width * x / 12.0;

        canvas.drawLine(
          Offset(
            px,
            plot.top,
          ),
          Offset(
            px,
            plot.bottom,
          ),
          gridPaint,
        );
      }

      for (int y = 0; y <= 12; y++) {
        final double py = plot.bottom - plot.height * y / 12.0;

        canvas.drawLine(
          Offset(
            plot.left,
            py,
          ),
          Offset(
            plot.right,
            py,
          ),
          gridPaint,
        );
      }
    }

    canvas.drawRect(
      plot,
      axisPaint,
    );

    // ------------------------------------------------------------------------
    // TEXT HELPER
    // ------------------------------------------------------------------------

    void drawText(
      String value,
      Offset position, {
      double fontSize = 10,
      Color color = kMuted,
    }) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      painter.layout();

      painter.paint(
        canvas,
        position,
      );
    }

    // ------------------------------------------------------------------------
    // AXIS LABELS
    // ------------------------------------------------------------------------

    for (int i = 0; i <= 12; i += 2) {
      final double py = plot.bottom - plot.height * i / 12.0;

      drawText(
        i == 0 ? '0' : '${i}.0mA',
        Offset(
          mobile ? 1 : 7,
          py - 7,
        ),
        fontSize: mobile ? 8 : 10,
      );
    }

    for (int i = 0; i <= 12; i += 2) {
      final double px = plot.left + plot.width * i / 12.0;

      drawText(
        '${i}.0',
        Offset(
          px - 7,
          plot.bottom + 7,
        ),
        fontSize: mobile ? 8 : 10,
      );
    }

    drawText(
      'IC (mA)',
      Offset(
        mobile ? 3 : 7,
        plot.top + plot.height * .43,
      ),
      fontSize: mobile ? 8 : 10,
    );

    drawText(
      'VCE (V)',
      Offset(
        plot.left + plot.width * .42,
        size.height - 24,
      ),
      fontSize: mobile ? 8 : 10,
    );

    // ------------------------------------------------------------------------
    // OUTPUT CHARACTERISTIC CURVES
    // ------------------------------------------------------------------------

    const List<double> baseCurrents = [
      1.7,
      3.5,
      5.3,
      7.2,
      9.3,
    ];

    const List<String> labels = [
      '100µA',
      '200µA',
      '300µA',
      '400µA',
      '500µA',
    ];

    for (int curve = 0; curve < baseCurrents.length; curve++) {
      final Path path = Path();

      for (int i = 0; i <= 240; i++) {
        final double xValue = i / 20.0;

        final double knee = 1.0 -
            math.exp(
              -xValue / .52,
            );

        final double slope = xValue > 1.0 ? (xValue - 1.0) * .055 : 0.0;

        final double current = math.min(
          11.7,
          baseCurrents[curve] * (knee + slope),
        );

        final double x = plot.left + plot.width * xValue / 12.0;

        final double y = plot.bottom - plot.height * current / 12.0;

        if (i == 0) {
          path.moveTo(
            x,
            y,
          );
        } else {
          path.lineTo(
            x,
            y,
          );
        }
      }

      canvas.drawPath(
        path,
        curvePaint,
      );

      drawText(
        labels[curve],
        Offset(
          plot.right - (mobile ? 43 : 57),
          plot.top + 18 + curve * (mobile ? 34 : 42),
        ),
        fontSize: mobile ? 8 : 11,
        color: const Color(
          0xFF70F48E,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // LOAD LINE
    // ------------------------------------------------------------------------

    final double maxCurrent = rc <= 0 ? 0.0 : vcc / rc * 1000.0;

    final double yIntercept = math.min(
      12.0,
      maxCurrent,
    );

    final Path loadPath = Path();

    loadPath.moveTo(
      plot.left,
      plot.bottom - plot.height * yIntercept / 12.0,
    );

    loadPath.lineTo(
      plot.right,
      plot.bottom,
    );

    canvas.drawPath(
      loadPath,
      loadPaint,
    );

    // ------------------------------------------------------------------------
    // LOAD LINE LABEL
    // ------------------------------------------------------------------------

    if (!mobile) {
      drawText(
        'IC=${maxCurrent.toStringAsFixed(2)}mA',
        Offset(
          plot.left + 4,
          plot.top + plot.height * .48,
        ),
        color: const Color(
          0xFFFF8175,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // Q POINT
    // ------------------------------------------------------------------------

    final double safeQvce = qVce.clamp(0.0, 12.0).toDouble();

    final double safeQic = qIc.clamp(0.0, 12.0).toDouble();

    final double qx = plot.left + plot.width * safeQvce / 12.0;

    final double qy = plot.bottom - plot.height * safeQic / 12.0;

    // Glow
    final Paint glowPaint = Paint()
      ..color = const Color(
        0x4465FF72,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawCircle(
      Offset(qx, qy),
      mobile ? 9 : 12,
      glowPaint,
    );

    // Crosshair
    final Paint crossPaint = Paint()
      ..color = const Color(
        0xFF65FF72,
      )
      ..strokeWidth = mobile ? 1.8 : 2.0;

    canvas.drawLine(
      Offset(
        qx - 12,
        qy,
      ),
      Offset(
        qx + 12,
        qy,
      ),
      crossPaint,
    );

    canvas.drawLine(
      Offset(
        qx,
        qy - 12,
      ),
      Offset(
        qx,
        qy + 12,
      ),
      crossPaint,
    );

    canvas.drawCircle(
      Offset(qx, qy),
      mobile ? 4 : 5,
      Paint()
        ..color = const Color(
          0xFF72FF7B,
        ),
    );

    // ------------------------------------------------------------------------
    // Q POINT TEXT
    // ------------------------------------------------------------------------

    final double labelX = plot.left + plot.width * .47;

    final double labelY = plot.top + plot.height * .38;

    drawText(
      'Q-POINT: IC=${qIc.toStringAsFixed(2)}mA',
      Offset(
        labelX,
        labelY,
      ),
      fontSize: mobile ? 8 : 11,
      color: kWhite,
    );

    drawText(
      'VCE=${qVce.toStringAsFixed(2)}V',
      Offset(
        labelX,
        labelY + (mobile ? 13 : 17),
      ),
      fontSize: mobile ? 8 : 11,
      color: kWhite,
    );
  }

  @override
  bool shouldRepaint(
    covariant ChartPainter oldDelegate,
  ) {
    return oldDelegate.qVce != qVce ||
        oldDelegate.qIc != qIc ||
        oldDelegate.vcc != vcc ||
        oldDelegate.rc != rc ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.mobile != mobile;
  }
}
