import 'dart:math';
import 'package:flutter/material.dart';

import '../models/client.dart';
import '../constants/app_colors.dart';

import '../components/arca_logo.dart';
import '../components/risk_gauge.dart';
import '../components/filter_bar.dart';
import '../components/risk_chart_card.dart';
import 'risk_dashboard_page.dart';

class RiskDashboardScreen extends StatefulWidget {
  const RiskDashboardScreen({super.key});

  @override
  State<RiskDashboardScreen> createState() => _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends State<RiskDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  late Animation<double> _arcAnimation;

  String _selectedFilter = 'Alto';

  final List<String> _filterOptions = [
    'Alto',
    'Medio',
    'Bajo',
  ];

  final TextEditingController _searchController = TextEditingController();

  List<Client> _allClients = [];
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();

    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _arcAnimation = CurvedAnimation(
      parent: _arcController,
      curve: Curves.easeOutCubic,
    );

    _arcController.forward();

    _allClients = List.generate(
      50,
      (i) => Client(
        id: 'ID${1000 + i}',
        risk: Random().nextInt(100),
      ),
    );

    _filteredClients = List.from(_allClients);
  }

  @override
  void dispose() {
    _arcController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchById() {
    final id = _searchController.text.trim();

    setState(() {
      if (id.isEmpty) {
        _filteredClients = List.from(_allClients);
      } else {
        _filteredClients = _allClients
            .where(
              (c) => c.id.toLowerCase() == id.toLowerCase(),
            )
            .toList();
      }
    });
  }

  int get _totalRisk => _filteredClients.isEmpty
      ? 0
      : _filteredClients.fold(
              0,
              (sum, c) => sum + c.risk,
            ) ~/
          _filteredClients.length;

  List<double> get _chartData =>
      _filteredClients.map((c) => c.risk.toDouble()).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Column(
            children: [
              const ArcaLogo(),

              const SizedBox(height: 24),

              AnimatedBuilder(
                animation: _arcAnimation,
                builder: (_, __) => RiskGauge(
                  total: _totalRisk,
                  progress: _arcAnimation.value,
                ),
              ),

              const SizedBox(height: 24),

              FilterBar(
                selected: _selectedFilter,
                options: _filterOptions,
                searchController: _searchController,
                onSearch: _searchById,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });

                  if (value == 'Alto') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RiskDashboardPage(),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              RiskChartCard(
                chartData: _chartData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}