import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DonutSegment {
  final double value;
  final Color color;
  final String label;
  const DonutSegment(this.value, this.color, this.label);
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final String centerText;
  final String centerSubtext;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 190,
    this.centerText = '',
    this.centerSubtext = '',
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(segments, total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerText,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  if (centerSubtext.isNotEmpty)
                    Text(centerSubtext,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((s) {
            final double pct = total > 0 ? (s.value / total * 100) : 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${s.label} ${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;
  _DonutPainter(this.segments, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    double start = -pi / 2;

    final bg = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, bg);

    if (total <= 0) return;
    for (final s in segments) {
      final sweep = (s.value / total) * 2 * pi;
      final p = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}