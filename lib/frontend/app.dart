import 'package:flutter/material.dart';
import 'pages/risk_dashboard_screen.dart';
import 'theme/app_theme.dart';

class ArcaApp extends StatelessWidget {
  const ArcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const RiskDashboardPage(),
    );
  }
}