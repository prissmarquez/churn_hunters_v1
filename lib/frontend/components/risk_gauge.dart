import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'gauge_painter.dart';

class RiskGauge extends StatelessWidget {
  final int total;
  final double progress;

  const RiskGauge({
    super.key,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: GaugePainter(
          progress: progress,
        ),
        child: Center(
          child: Text(
            '$total',
            style: const TextStyle(
              color: redColor,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}