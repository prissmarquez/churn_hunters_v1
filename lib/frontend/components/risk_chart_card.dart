import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'line_chart_painter.dart';

class RiskChartCard extends StatelessWidget {
  final List<double> chartData;

  const RiskChartCard({
    super.key,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: redColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gráfica de Riesgo Total',
            style: TextStyle(
              color: whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: max(
                  300,
                  chartData.length * 12.0,
                ),
                child: CustomPaint(
                  painter: LineChartPainter(
                    seriesData: chartData,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}