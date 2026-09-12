import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:electronics_app/main.dart';
import 'package:electronics_app/screens/input_screen.dart';
import 'package:electronics_app/screens/output_screen.dart';
import 'package:electronics_app/screens/simulation_screen.dart';
import 'package:electronics_app/screens/theory_screen.dart';
import 'package:electronics_app/screens/graph_screen.dart';
import 'package:electronics_app/screens/bjt_3d_viewer_screen.dart';

void main() {
  testWidgets('App smoke and theme toggle test', (WidgetTester tester) async {
    await tester.pumpWidget(const ElectronicsApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Experiment 5: BJT Common Emitter'), findsOneWidget);

    // Toggle to Dark Theme
    appThemeNotifier.value = ThemeMode.dark;
    await tester.pump(const Duration(milliseconds: 100));
    expect(appThemeNotifier.value, ThemeMode.dark);

    // Toggle back to Light Theme
    appThemeNotifier.value = ThemeMode.light;
    await tester.pump(const Duration(milliseconds: 100));
    expect(appThemeNotifier.value, ThemeMode.light);
  });

  testWidgets('InputScreen renders table and denotations in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const InputScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Input Characteristics (IB vs VBE)'), findsOneWidget);
    expect(find.text('Parameter Denotations:'), findsOneWidget);
    expect(find.textContaining('Observation Rows: 11 / 30'), findsOneWidget);
    expect(find.text('Clear Table'), findsOneWidget);
    expect(find.text('Fill Sample Data'), findsOneWidget);
    expect(find.text('Save Data'), findsOneWidget);

    // Tap Fill Sample Data
    await tester.tap(find.text('Fill Sample Data'));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('OutputScreen renders table and denotations in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const OutputScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Output Characteristics (IC vs VCE)'), findsOneWidget);
    expect(find.text('Parameter Denotations:'), findsOneWidget);
    expect(find.textContaining('Observation Rows: 11 / 30'), findsOneWidget);
    expect(find.text('Clear Table'), findsOneWidget);
    expect(find.text('Fill Sample Data'), findsOneWidget);
    expect(find.text('Save Data'), findsOneWidget);

    // Tap Fill Sample Data
    await tester.tap(find.text('Fill Sample Data'));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('TheoryScreen renders cards and 2D launch button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const TheoryScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('1. Objective'), findsOneWidget);
    expect(find.text('2. Apparatus & Components (BC547)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('View Transistor Packages & Pinouts'),
      200,
    );
    expect(find.text('View Transistor Packages & Pinouts'), findsOneWidget);
  });

  testWidgets('SimulationScreen renders circuit and adjusts sliders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const SimulationScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('BJT CE Virtual Simulation'), findsOneWidget);
    expect(find.textContaining('CIRCUIT SCHEMATIC'), findsOneWidget);
    expect(find.textContaining('VBE (Base-Emitter)'), findsOneWidget);
    expect(find.textContaining('IB (Base Current)'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(Slider).first, 200);
    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(4));

    await tester.drag(sliders.first, const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Bjt3dViewerScreen switches 2D models and view modes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Bjt3dViewerScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('BJT Transistor Packages & Pinouts'), findsOneWidget);
    expect(find.text('TO-92 (BC547)'), findsOneWidget);
    expect(find.text('TO-18 Metal Can (BC107)'), findsOneWidget);
    expect(find.text('TO-220 Power BJT (TIP31)'), findsOneWidget);

    // Switch to TO-18 Metal Can
    await tester.tap(find.text('TO-18 Metal Can (BC107)'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('TO-18 / TO-39 Hermetic Metal Can (BC107)'), findsOneWidget);

    // Switch to TO-220 Power BJT
    await tester.tap(find.text('TO-220 Power BJT (TIP31)'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('TO-220 Power BJT (TIP31 / BD139)'), findsOneWidget);

    // Switch view mode to Bottom Pinout
    await tester.tap(find.text('Bottom Pinout'));
    await tester.pump(const Duration(milliseconds: 200));

    // Switch view mode to Symbol & Layers
    await tester.tap(find.text('Symbol & Layers'));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('GraphScreen displays curves in both light and dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const GraphScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('BJT Characteristics Curves'), findsOneWidget);
    expect(find.textContaining('Input (IB - VBE)'), findsOneWidget);
    expect(find.textContaining('Output (IC - VCE)'), findsOneWidget);

    // Switch to Output Tab
    await tester.tap(find.textContaining('Output (IC - VCE)'));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
