import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BarData {
  final String label;
  final double value; // porcentaje
  const BarData(this.label, this.value);
}

class BarChart extends StatelessWidget {
  final List<BarData> data;
  final double height;
  const BarChart({super.key, required this.data, this.height = 170});

  Color _color(double v, double max) {
    final r = max > 0 ? v / max : 0.0;
    if (r >= 0.66) return AppColors.redAccent;
    if (r >= 0.33) return AppColors.amber;
    return const Color(0xFF2ECC71);
  }

  String _short(String s) => s.length > 10 ? '${s.substring(0, 10)}…' : s;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Sin datos por territorio.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    final maxV = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height + 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((d) {
            final double barH = maxV > 0 ? (d.value / maxV) * height : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${d.value.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: barH,
                    decoration: BoxDecoration(
                      color: _color(d.value, maxV),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 52,
                    child: Text(_short(d.label),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}