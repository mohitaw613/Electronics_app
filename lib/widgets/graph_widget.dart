import 'package:flutter/material.dart';

/// Reusable placeholder graph canvas widget for Experiment 5 curves.
/// (Assigned to Ishan for custom graph rendering / plotting).
class ExperimentGraphWidget extends StatelessWidget {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<Offset> points;

  const ExperimentGraphWidget({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    this.points = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: points.isEmpty
                  ? Text(
                      'No points plotted yet.\nEnter readings to render $xLabel vs $yLabel curve.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    )
                  : Text(
                      '${points.length} points ready for plotting',
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
