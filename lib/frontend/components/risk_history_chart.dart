import 'package:churn_v1/frontend/constants/app_colors.dart';
import 'package:flutter/material.dart';


class RiskHistoryChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final double height;

  const RiskHistoryChart({
    required this.data,
    this.labels = const ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'],
    this.height = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de Riesgo',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _RiskLineChartPainter(data: data, labels: labels),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskLineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  _RiskLineChartPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 40;
    const double rightPad = 8;
    const double topPad = 8;
    const double bottomPad = 24;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 11);

    // Cuadrícula + etiquetas Y (0, 25, 50, 75, 100)
    for (int i = 0; i <= 4; i++) {
      final pct = i * 25;
      final y = topPad + chartH * (1 - pct / 100);
      _dashedLine(
          canvas, Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      _text(canvas, '$pct%', Offset(0, y - 7), muted, leftPad - 6,
          TextAlign.right);
    }

    if (data.isEmpty) return;
    final n = data.length;

    Offset pointAt(int i) {
      final x = leftPad + (n == 1 ? chartW / 2 : chartW * i / (n - 1));
      final v = data[i].clamp(0.0, 100.0);
      final y = topPad + chartH * (1 - v / 100);
      return Offset(x, y);
    }

    // Etiquetas X (meses)
    for (int i = 0; i < n && i < labels.length; i++) {
      final p = pointAt(i);
      _text(canvas, labels[i], Offset(p.dx - 18, size.height - bottomPad + 4),
          muted, 36, TextAlign.center);
    }

    // Relleno con degradado bajo la línea
    final fillPath = Path()..moveTo(pointAt(0).dx, topPad + chartH);
    for (int i = 0; i < n; i++) {
      fillPath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    fillPath.lineTo(pointAt(n - 1).dx, topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x66E74C3C), Color(0x00E74C3C)],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Línea
    final linePaint = Paint()
      ..color = AppColors.redAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < n; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Puntos
    final dotPaint = Paint()..color = AppColors.redAccent;
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pointAt(i), 4, dotPaint);
    }
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (end - start).distance;
    if (total == 0) return;
    final dir = (end - start) / total;
    double dist = 0;
    while (dist < total) {
      double segEnd = dist + dash;
      if (segEnd > total) segEnd = total;
      canvas.drawLine(start + dir * dist, start + dir * segEnd, paint);
      dist += dash + gap;
    }
  }

  void _text(Canvas canvas, String text, Offset pos, TextStyle style,
      double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RiskLineChartPainter old) =>
      old.data != data || old.labels != labels;
}