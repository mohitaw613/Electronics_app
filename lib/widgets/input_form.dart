import 'package:flutter/material.dart';

/// Reusable input field component for entering numerical electrical readings.
class LabInputField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final String? hint;

  const LabInputField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
