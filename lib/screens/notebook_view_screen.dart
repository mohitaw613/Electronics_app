import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_realistic_flipbook/flutter_realistic_flipbook.dart';
import 'package:electronics_app/utils/notebook_paginator.dart';
import 'package:electronics_app/widgets/notebook_page_spread.dart';

class NotebookViewScreen extends StatefulWidget {
  const NotebookViewScreen({Key? key}) : super(key: key);

  @override
  State<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends State<NotebookViewScreen> {
  final FlipbookController _flipbookController = FlipbookController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  final String rawLabContent = '''
EXPERIMENT 04: BJT Common Emitter Characteristics
--------------------------------------------------
1. Objective:
To study the input and output characteristics of a NPN BJT in Common Emitter (CE) configuration.

2. Apparatus Required:
- NPN Transistor (BC547)
- DC Power Supplies (0-30V, 0-5V)
- Multimeters / Regulated Voltmeters
- Resistors (100kΩ, 1kΩ)
- Breadboard and Connecting Wires

3. Theory & Formulae:
In CE configuration, the emitter is common to both input and output circuits.
Input Characteristic: V_BE vs I_B at constant V_CE.
Output Characteristic: V_CE vs I_C at constant I_B.
Current Gain (beta) = ΔI_C / ΔI_B.

4. Procedure:
- Step 1: Connect the circuit diagram on the breadboard.
- Step 2: Fix V_CE to a constant value (e.g., 5V) and vary V_BE in steps of 0.1V. Note corresponding I_B.
- Step 3: Plot input characteristics curve.
- Step 4: Vary V_CE for different fixed values of I_B and record I_C.
- Step 5: Plot output characteristics.

5. Observations & Calculations:
- V_BE ranges from 0.0V to 0.8V.
- I_B ranges from 0µA to 50µA.
- Calculated DC current gain β lies within typical range 150-300.
''';

  @override
  Widget build(BuildContext context) {
    // Explicitly check if running on Android or iOS
    final bool isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: const Color(0xFF131927),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2638),
        elevation: 0,
        title: const Text(
          "3D Lab Record Flipbook",
          style: TextStyle(fontFamily: 'Courier', fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final List<String> pageChunks = paginateNotebookContent(
              rawLabContent,
              maxLinesPerPage: isMobile ? 14 : 20,
            );

            final List<Widget> pages = [];

            // --- COVER PAGE ---
            pages.add(
              Container(
                color: const Color(0xFF00838F),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: isMobile ? 260 : 240,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFA),
                      border: Border.all(
                        color: const Color(0xFFC5B99F),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            "NIT ROURKELA - LAB RECORD",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRow("Name:", "Mohit Awasthi"),
                        const SizedBox(height: 6),
                        _buildRow("Roll No:", "125CS0168"),
                        const SizedBox(height: 6),
                        _buildRow("Semester:", "3rd Semester"),
                        const SizedBox(height: 6),
                        _buildRow("Sessional:", "BJT CE Char."),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // --- CONTENT PAGES ---
            for (int i = 0; i < pageChunks.length; i++) {
              pages.add(
                NotebookPageSpread(
                  title: "BJT & CE Engineering Suite",
                  content: pageChunks[i],
                  pageNumber: i + 2,
                  wrapLongLines: true,
                ),
              );
            }

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  color: const Color(0xFF1E2638),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Report Generated for: Mohit Awasthi (125CS0168)",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.edit,
                          size: 13,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          "Re-Configure",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: isMobile ? 0.75 : 1.35,
                        child: RealisticFlipbook(
                          controller: _flipbookController,
                          pages: pages
                              .map(
                                (page) => FlipbookPage(
                                  widgetBuilder: (context) => page,
                                ),
                              )
                              .toList(),
                          singlePage: isMobile,
                          flipDuration: const Duration(milliseconds: 500),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}
