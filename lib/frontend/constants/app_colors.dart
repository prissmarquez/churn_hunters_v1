// import 'package:flutter/material.dart';

// const bgColor = Color(0xFF1A1A2E);
// const cardColor = Color(0xFF16213E);
// const redColor = Color(0xFFE63946);
// const whiteColor = Colors.white;

import 'package:flutter/material.dart';

class AppColors {
  // Fondos y superficies
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceAlt = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);

  // Acentos / riesgo
  static const Color red = Color(0xFFC0392B);
  static const Color redAccent = Color(0xFFE74C3C);
  static const Color amber = Color(0xFFF0A500);

  // Texto
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF888888);

  // Burbujas de chat
  static const Color bubbleOut = Color(0xFF4A1515);
  static const Color bubbleIn = Color(0xFF222222);
  static const Color bubbleOutText = Color(0xFFF0C0C0);
  static const Color bubbleInText = Color(0xFFD0D0D0);

  static const Color white = Colors.white;
}

// Alias de compatibilidad para el home (migrar a AppColors poco a poco)
const bgColor = AppColors.background;
const cardColor = AppColors.surface;
const redColor = AppColors.redAccent;
const whiteColor = AppColors.textPrimary;