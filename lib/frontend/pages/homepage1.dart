import 'package:flutter/material.dart';
import 'risk_dashboard_screen.dart'; // importa el dashboard

class Homepage1 extends StatefulWidget {
  const Homepage1({super.key});

  @override
  State<Homepage1> createState() => _Homepage1State();
}

class _Homepage1State extends State<Homepage1> {
  @override
  Widget build(BuildContext context) {
    return const RiskDashboardScreen();
  }
}