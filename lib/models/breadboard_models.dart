import 'package:flutter/material.dart';

enum BreadboardTerminal {
  vbbPositive,
  vbbGnd,
  vccPositive,
  vccGnd,
  r1In,
  r1Out,
  r2In,
  r2Out,
  bjtBase,
  bjtCollector,
  bjtEmitter,
  commonGnd,
}

class BreadboardWire {
  final String id;
  final BreadboardTerminal from;
  final BreadboardTerminal to;
  final Color color;

  const BreadboardWire({
    required this.id,
    required this.from,
    required this.to,
    this.color = Colors.blueAccent,
  });

  bool connects(BreadboardTerminal a, BreadboardTerminal b) {
    return (from == a && to == b) || (from == b && to == a);
  }
}
