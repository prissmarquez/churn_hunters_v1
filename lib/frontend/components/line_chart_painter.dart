import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LineChartPainter extends CustomPainter {
  final List<double> seriesData;

  LineChartPainter({
    required this.seriesData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double maxVal = 100;
    const double minVal = 0;

    final int n = seriesData.length;

    if (n == 0) return;

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    double xOf(int i) =>
        size.width * i / max(1, n - 1);

    double yOf(double v) =>
        size.height -
        (v - minVal) /
            (maxVal - minVal) *
            size.height;

    final path = Path();

    for (int i = 0; i < n; i++) {
      final x = xOf(i);
      final y = yOf(seriesData[i]);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = xOf(i - 1);
        final prevY = yOf(seriesData[i - 1]);

        final cpX = (prevX + x) / 2;

        path.cubicTo(
          cpX,
          prevY,
          cpX,
          y,
          x,
          y,
        );
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = redColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    const labelStyle = TextStyle(
      color: Colors.white54,
      fontSize: 10,
    );

    for (final v in [0, 20, 40, 60, 80, 100]) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          0,
          yOf(v.toDouble()) - 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    LineChartPainter oldDelegate,
  ) {
    return true;
  }
}