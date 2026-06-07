// import 'package:flutter/material.dart';

// import '../models/client.dart';
// import '../constants/app_colors.dart';
// import '../services/api_service.dart';

// import '../components/arca_logo.dart';
// import '../components/risk_gauge.dart';
// import '../components/filter_bar.dart';
// import '../components/client_list.dart';
// import 'client_analysis_page.dart';
// import 'report_page.dart';  

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _arcController;
//   late Animation<double> _arcAnimation;

//   final ApiService _api = ApiService();

//   String _selectedFilter = 'Alto';
//   final List<String> _filterOptions = ['Alto', 'Medio', 'Bajo'];

//   final TextEditingController _searchController = TextEditingController();

//   List<Client> _filteredClients = [];
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _arcController = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 1400));
//     _arcAnimation =
//         CurvedAnimation(parent: _arcController, curve: Curves.easeOutCubic);
//     _arcController.forward();
//     _filtrarPorNivel(_selectedFilter);
//   }

//   Future<void> _filtrarPorNivel(String nivel) async {
//     setState(() {
//       _selectedFilter = nivel;
//       _loading = true;
//     });
//     try {
//       final clientes = await _api.buscarPorNivel(nivel);
//       setState(() {
//         _filteredClients = clientes;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() => _loading = false);
//       debugPrint('Error cargando clientes: $e');
//     }
//   }

//   void _abrirCliente(String id) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (_) => ClientAnalysisPage(clientId: id)),
//     );
//   }

//   @override
//   void dispose() {
//     _arcController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _searchById() {
//     final id = _searchController.text.trim();
//     if (id.isEmpty) return;
//     _abrirCliente(id);
//   }

//   // Cantidad de clientes en el filtro actual (más útil que el promedio)
//   int get _totalClientes => _filteredClients.length;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       // dentro del Scaffold del build, junto a backgroundColor / body:
// floatingActionButton: FloatingActionButton.extended(
//   backgroundColor: redColor,
//   icon: const Icon(Icons.assessment_outlined, color: Colors.white),
//   label: const Text('Reporte', style: TextStyle(color: Colors.white)),
//   onPressed: () => Navigator.of(context).push(
//     MaterialPageRoute(builder: (_) => const ReportPage()),
//   ),
// ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           child: Column(
//             children: [
//               const ArcaLogo(),
//               const SizedBox(height: 24),
//               AnimatedBuilder(
//                 animation: _arcAnimation,
//                 builder: (_, __) => RiskGauge(
//                   total: _totalClientes,
//                   progress: _arcAnimation.value,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'clientes en riesgo $_selectedFilter',
//                 style: const TextStyle(color: whiteColor, fontSize: 14),
//               ),
//               const SizedBox(height: 24),
//               FilterBar(
//                 selected: _selectedFilter,
//                 options: _filterOptions,
//                 searchController: _searchController,
//                 onSearch: _searchById,
//                 onChanged: (value) => _filtrarPorNivel(value),
//               ),
//               const SizedBox(height: 24),
//               if (_loading)
//                 const Padding(
//                   padding: EdgeInsets.all(32),
//                   child: CircularProgressIndicator(color: redColor),
//                 )
//               else
//                 ClientList(
//                   clients: _filteredClients,
//                   onTap: (c) => _abrirCliente(c.id),
//                 ),

                
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../models/client.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';

import '../components/arca_logo.dart';
import '../components/risk_gauge.dart';
import '../components/filter_bar.dart';
import '../components/client_list.dart';
import 'client_analysis_page.dart';
import 'report_page.dart';
import 'ai_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  late Animation<double> _arcAnimation;

  final ApiService _api = ApiService();

  String _selectedFilter = 'Alto';
  final List<String> _filterOptions = ['Alto', 'Medio', 'Bajo'];
  String _selectedSort = 'riesgo_desc';

  final TextEditingController _searchController = TextEditingController();

  List<Client> _filteredClients = [];
  Map<String, dynamic>? _resumen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _arcAnimation =
        CurvedAnimation(parent: _arcController, curve: Curves.easeOutCubic);
    _cargarResumen();
    _filtrarPorNivel(_selectedFilter);
  }

  Future<void> _cargarResumen() async {
    try {
      final r = await _api.fetchResumen();
      setState(() => _resumen = r);
      _arcController.forward(from: 0);
    } catch (e) {
      debugPrint('Error resumen: $e');
    }
  }

  Future<void> _filtrarPorNivel(String nivel) async {
    setState(() {
      _selectedFilter = nivel;
      _loading = true;
    });
    try {
      final clientes = await _api.buscarPorNivel(nivel);
      setState(() {
        _filteredClients = clientes;
        _loading = false;
      });
      _arcController.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error cargando clientes: $e');
    }
  }

  void _abrirCliente(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientAnalysisPage(clientId: id)),
    );
  }

  @override
  void dispose() {
    _arcController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchById() {
    final id = _searchController.text.trim();
    if (id.isEmpty) return;
    _abrirCliente(id);
  }

  List<Client> get _sortedClients {
    final list = List<Client>.from(_filteredClients);
    if (_selectedSort == 'riesgo_asc') {
      list.sort((a, b) => a.risk.compareTo(b.risk));
    } else if (_selectedSort == 'estado_az') {
      list.sort((a, b) => a.state.compareTo(b.state));
    } else if (_selectedSort == 'estado_za') {
      list.sort((a, b) => b.state.compareTo(a.state));
    } else if (_selectedSort == 'id_az') {
      list.sort((a, b) => a.id.compareTo(b.id));
    } else {
      list.sort((a, b) => b.risk.compareTo(a.risk)); // riesgo_desc (default)
    }
    return list;
  }

  double get _pctNivel {
    if (_resumen == null) return 0;
    final v = _resumen!['pct_${_selectedFilter.toLowerCase()}'];
    return (v is num) ? v.toDouble() : 0.0;
  }

  String _compact(num n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final cajas = (_resumen?['cajas_riesgo_alto'] ?? 0) as num;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'fab_ia',
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.redAccent, width: 1.4),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiChatPage()),
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.redAccent, size: 22),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab_report',
            backgroundColor: redColor,
            icon: const Icon(Icons.assessment_outlined, color: Colors.white),
            label: const Text('Reporte',
                style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const ArcaLogo(),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _arcAnimation,
                builder: (_, __) => RiskGauge(
                  total: _pctNivel.round(),
                  progress: _arcAnimation.value * (_pctNivel / 100),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '% de la cartera en riesgo $_selectedFilter',
                style: const TextStyle(color: whiteColor, fontSize: 14),
              ),
              if (cajas > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '≈ ${_compact(cajas)} cajas/mes en riesgo',
                  style: const TextStyle(
                      color: redColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 24),
              FilterBar(
                selected: _selectedFilter,
                options: _filterOptions,
                searchController: _searchController,
                onSearch: _searchById,
                onChanged: (value) => _filtrarPorNivel(value),
                selectedSort: _selectedSort,
                onSortChanged: (value) =>
                    setState(() => _selectedSort = value),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: redColor),
                )
              else
                ClientList(
                  clients: _sortedClients,
                  onTap: (c) => _abrirCliente(c.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}