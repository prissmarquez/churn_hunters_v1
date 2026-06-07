import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../components/donut_chart.dart';
import '../components/bar_chart.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _resumen;
  Map<String, dynamic>? _impacto;
  List<BarData> _territorios = [];
  List<BarData> _coolers = [];
  List<BarData> _temporalidad = [];

  // AI answers for each of the 3 business questions
  String? _aiResumen;
  String? _aiVariables;
  String? _aiTerritorio;
  String? _aiCoolers;

  bool _aiResumenError = false;
  bool _aiVariablesError = false;
  bool _aiTerritorioError = false;
  bool _aiCoolersError = false;

  bool _loading = true;

  static const _preguntaResumen =
      'Genera un resumen ejecutivo breve (3-4 líneas) para dirección: '
      'por qué estamos perdiendo clientes, qué factores destacan en los de '
      'riesgo alto, y las 3 acciones que el equipo comercial debería priorizar.';

  static const _preguntaVariables =
      '¿Qué variables o comportamientos del cliente influyen más en que deje '
      'de comprar? Menciona las 3 más importantes con un dato concreto de la '
      'cartera actual. Sé directo y usa viñetas.';

  static const _preguntaTerritorio =
      '¿El territorio o zona geográfica influye en la pérdida de clientes? '
      '¿Cuáles son los 2 territorios más críticos y qué los caracteriza? '
      'Sé concreto con los datos.';

  static const _preguntaCoolers =
      '¿La cantidad de coolers que tiene un cliente afecta su riesgo de churn? '
      'Explica la relación: ¿los clientes con más coolers tienen más o menos '
      'riesgo? ¿Por qué? Apóyate en los datos de la cartera.';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    // Load summary
    try {
      final r = await _api.fetchResumen();
      setState(() {
        _resumen = r;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error resumen reporte: $e');
    }

    // Load territory chart
    try {
      final t = await _api.fetchRiesgoPorTerritorio(top: 8);
      setState(() => _territorios = t
          .map((m) => BarData((m['territorio'] ?? '').toString(),
              ((m['riesgo_pct'] ?? 0) as num).toDouble()))
          .toList());
    } catch (e) {
      debugPrint('Error territorio: $e');
    }

    // Load coolers chart
    try {
      final c = await _api.fetchRiesgoPorCoolers();
      setState(() => _coolers = c
          .map((m) => BarData((m['coolers'] ?? '').toString(),
              ((m['riesgo_pct'] ?? 0) as num).toDouble()))
          .toList());
    } catch (e) {
      debugPrint('Error coolers: $e');
    }

    // Load business impact
    try {
      final imp = await _api.fetchImpacto();
      setState(() => _impacto = imp);
    } catch (e) {
      debugPrint('Error impacto: $e');
    }

    // Load seasonality chart
    try {
      final meses = await _api.fetchChurnPorMes();
      setState(() => _temporalidad = meses.map((m) {
            final raw = (m['mes'] ?? '').toString();
            final label = _mesLabel(raw);
            final val = ((m['churn_pct'] ?? 0) as num).toDouble();
            return BarData(label, val);
          }).toList());
    } catch (e) {
      debugPrint('Error estacionalidad: $e');
    }

    // AI: executive summary
    _api.preguntar(_preguntaResumen).then((txt) {
      if (mounted) setState(() => _aiResumen = txt);
    }).catchError((_) {
      if (mounted) setState(() => _aiResumenError = true);
    });

    // AI: variables that influence churn
    _api.preguntar(_preguntaVariables).then((txt) {
      if (mounted) setState(() => _aiVariables = txt);
    }).catchError((_) {
      if (mounted) setState(() => _aiVariablesError = true);
    });

    // AI: territory influence
    _api.preguntar(_preguntaTerritorio).then((txt) {
      if (mounted) setState(() => _aiTerritorio = txt);
    }).catchError((_) {
      if (mounted) setState(() => _aiTerritorioError = true);
    });

    // AI: cooler influence
    _api.preguntar(_preguntaCoolers).then((txt) {
      if (mounted) setState(() => _aiCoolers = txt);
    }).catchError((_) {
      if (mounted) setState(() => _aiCoolersError = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Reporte de Cartera'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.redAccent))
          : _resumen == null
              ? const Center(
                  child: Text('No se pudo cargar el reporte.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : _buildContent(),
    );
  }

  // Convierte "202402" → "Feb 24"
  String _mesLabel(String raw) {
    if (raw.length != 6) return raw;
    const meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                       'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final year = raw.substring(2, 4);
    final month = int.tryParse(raw.substring(4)) ?? 0;
    if (month < 1 || month > 12) return raw;
    return '${meses[month]} $year';
  }

  String _compact(num n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  Widget _buildContent() {
    final r = _resumen!;
    final total = (r['total'] as num).toInt();
    final alto = (r['alto'] as num).toInt();
    final medio = (r['medio'] as num).toInt();
    final bajo = (r['bajo'] as num).toInt();
    final pctAlto = (r['pct_alto'] as num).toDouble();
    final pctMedio = (r['pct_medio'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          const Text('Resumen de churn de la cartera',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$total clientes analizados',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // ── KPI cards ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _kpi(
                    'En riesgo ALTO',
                    '$alto',
                    '${pctAlto.toStringAsFixed(1)}% de la cartera',
                    AppColors.redAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpi('En riesgo medio', '$medio',
                    '${pctMedio.toStringAsFixed(1)}%', AppColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kpi('Clientes en riesgo bajo', '$bajo',
              '${(100 - pctAlto - pctMedio).toStringAsFixed(1)}%',
              const Color(0xFF2ECC71)),
          const SizedBox(height: 20),

          // ── Impacto de negocio ───────────────────────────────────────────
          if (_impacto != null) _impactoCard(_impacto!),
          if (_impacto != null) const SizedBox(height: 20),

          // ── Donut ────────────────────────────────────────────────────────
          _card(
            'Distribución de riesgo',
            null,
            Center(
              child: DonutChart(
                centerText: '${pctAlto.toStringAsFixed(1)}%',
                centerSubtext: 'riesgo alto',
                segments: [
                  DonutSegment(alto.toDouble(), AppColors.redAccent, 'Alto'),
                  DonutSegment(medio.toDouble(), AppColors.amber, 'Medio'),
                  DonutSegment(
                      bajo.toDouble(), const Color(0xFF2ECC71), 'Bajo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Estacionalidad ───────────────────────────────────────────────
          _card(
            'Estacionalidad del churn (últimos 24 meses)',
            Icons.trending_up,
            _temporalidad.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pico en Feb y Nov · Valle en May y Ago',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      BarChart(data: _temporalidad, height: 120),
                    ],
                  )
                : Row(children: const [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.redAccent)),
                    SizedBox(width: 10),
                    Text('Cargando...', style: TextStyle(color: AppColors.textSecondary)),
                  ]),
          ),
          const SizedBox(height: 20),

          // ── AI executive summary ─────────────────────────────────────────
          _card(
            '¿Por qué se están yendo? · Resumen IA',
            null,
            _aiWidget(_aiResumen, _aiResumenError),
          ),
          const SizedBox(height: 28),

          // ══ PREGUNTA 1 ══════════════════════════════════════════════════
          _sectionHeader(
            '1',
            '¿Qué variables influyen más en que un cliente deje de comprar?',
          ),
          const SizedBox(height: 12),
          _card(
            'Factores de riesgo más importantes',
            Icons.bar_chart_rounded,
            _aiWidget(_aiVariables, _aiVariablesError),
          ),
          const SizedBox(height: 28),

          // ══ PREGUNTA 2 ══════════════════════════════════════════════════
          _sectionHeader(
            '2',
            '¿El territorio o zona geográfica influye en la pérdida de clientes?',
          ),
          const SizedBox(height: 12),
          _card(
            'Riesgo promedio por estado',
            Icons.map_outlined,
            BarChart(data: _territorios),
          ),
          const SizedBox(height: 12),
          _card(
            'Análisis IA · Territorios',
            null,
            _aiWidget(_aiTerritorio, _aiTerritorioError),
          ),
          const SizedBox(height: 28),

          // ══ PREGUNTA 3 ══════════════════════════════════════════════════
          _sectionHeader(
            '3',
            '¿La cantidad de coolers que tiene un cliente afecta su riesgo de churn?',
          ),
          const SizedBox(height: 12),
          if (_coolers.isNotEmpty)
            _card(
              'Riesgo promedio por cantidad de coolers',
              Icons.kitchen_outlined,
              BarChart(data: _coolers),
            )
          else
            _card(
              'Riesgo por coolers',
              Icons.kitchen_outlined,
              const Text(
                'No hay datos de coolers disponibles en la cartera actual.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          _card(
            'Análisis IA · Coolers',
            null,
            _aiWidget(_aiCoolers, _aiCoolersError),
          ),
        ],
      ),
    );
  }

  Widget _impactoCard(Map<String, dynamic> imp) {
    final cajasAlto  = (imp['cajas_alto']  as num).toInt();
    final cajasTotal = (imp['cajas_total'] as num).toInt();
    final rec20      = (imp['recuperacion_20pct'] as num).toInt();
    final rec30      = (imp['recuperacion_30pct'] as num).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A0A0A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Impacto de negocio estimado',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _impactoKpi(
                  _compact(cajasAlto),
                  'cajas/mes\nen riesgo ALTO',
                  AppColors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _impactoKpi(
                  _compact(cajasTotal),
                  'cajas/mes\nen riesgo total',
                  AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Escenario de retención',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _scenarioRow('Retener 20% de clientes alto riesgo',
                    '+${_compact(rec20)} cajas/mes'),
                const SizedBox(height: 4),
                _scenarioRow('Retener 30% de clientes alto riesgo',
                    '+${_compact(rec30)} cajas/mes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactoKpi(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
      ],
    );
  }

  Widget _scenarioRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.arrow_forward, color: Color(0xFF2ECC71), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12)),
        ),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF2ECC71),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String number, String question) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.redAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(question,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3)),
        ),
      ],
    );
  }

  Widget _aiWidget(String? text, bool error) {
    if (text != null) {
      return Text(text,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, height: 1.45));
    }
    if (error) {
      return const Text(
        'No se pudo generar el análisis. Revisa la conexión con la IA.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Row(
      children: const [
        SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.redAccent)),
        SizedBox(width: 10),
        Text('Generando análisis...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _kpi(String label, String value, String sub, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _card(String title, IconData? icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.redAccent, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
