import 'package:flutter/material.dart';
import 'gauge_painter2.dart';

class RiskGauge extends StatelessWidget {
  final int total;
  final double progress;

  const RiskGauge({required this.total, required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: GaugePainter(progress: progress),
        child: Center(
          child: Text(
            '$total',
            style: const TextStyle(
              color: Color(0xFFC0392B),
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}