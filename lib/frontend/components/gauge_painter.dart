import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GaugePainter extends CustomPainter {
  final double progress;

  GaugePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 8;

    const startAngle = pi * 0.75;
    const sweepFull = pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweepFull * progress,
      false,
      Paint()
        ..color = redColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}