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
  List<BarData> _territorios = [];
  String? _aiTexto;
  bool _aiError = false;
  bool _loading = true;

  static const _pregunta =
      'Genera un resumen ejecutivo breve para direccion: por que estamos '
      'perdiendo clientes, que factores destacan en los de riesgo alto, y las '
      '3 acciones que el equipo comercial deberia priorizar. Se conciso.';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
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
    try {
      final t = await _api.fetchRiesgoPorTerritorio(top: 8);
      setState(() => _territorios = t
          .map((m) => BarData((m['territorio'] ?? '').toString(),
              ((m['riesgo_pct'] ?? 0) as num).toDouble()))
          .toList());
    } catch (e) {
      debugPrint('Error territorio: $e');
    }
    try {
      final txt = await _api.preguntar(_pregunta);
      setState(() => _aiTexto = txt);
    } catch (e) {
      setState(() => _aiError = true);
      debugPrint('Error IA reporte: $e');
    }
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

  Widget _buildContent() {
    final r = _resumen!;
    final total = (r['total'] as num).toInt();
    final alto = (r['alto'] as num).toInt();
    final medio = (r['medio'] as num).toInt();
    final bajo = (r['bajo'] as num).toInt();
    final pctAlto = (r['pct_alto'] as num).toDouble();
    final pctMedio = (r['pct_medio'] as num).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de churn de la cartera',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$total clientes analizados',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _kpi('En riesgo ALTO', '$alto',
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
          const SizedBox(height: 24),

          _card(
            'Distribución de riesgo',
            Center(
              child: DonutChart(
                centerText: '${pctAlto.toStringAsFixed(1)}%',
                centerSubtext: 'riesgo alto',
                segments: [
                  DonutSegment(alto.toDouble(), AppColors.redAccent, 'Alto'),
                  DonutSegment(medio.toDouble(), AppColors.amber, 'Medio'),
                  DonutSegment(bajo.toDouble(), const Color(0xFF2ECC71), 'Bajo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gráfica de barras: riesgo por estado / territorio
          _card(
            'Riesgo promedio por estado',
            BarChart(data: _territorios),
          ),
          const SizedBox(height: 20),

          // ¿Dónde usamos Machine Learning?
          _card(
            '¿Dónde usamos Machine Learning?',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bullet(
                    'Un modelo XGBoost predice la probabilidad de que cada cliente deje de comprar el próximo mes, usando su historial (tendencia, recencia y frecuencia de compra).'),
                _bullet(
                    '241,805 clientes evaluados, con un AUC de 0.965 sobre datos de prueba.'),
                _bullet(
                    'Ese score es la base de toda la app: el nivel de riesgo, la lista, los filtros, el % de cartera y este reporte salen del modelo.'),
                _bullet(
                    'La IA (Gemini) no predice: interpreta los resultados del modelo y los traduce en explicaciones y acciones para el equipo comercial.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Análisis de la IA
          _card(
            '¿Por qué se están yendo? · Análisis IA',
            _aiTexto != null
                ? Text(_aiTexto!,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45))
                : _aiError
                    ? const Text(
                        'No se pudo generar el análisis de IA. Revisa la conexión con Gemini.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13))
                    : Row(
                        children: const [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.redAccent)),
                          SizedBox(width: 10),
                          Text('Generando análisis...',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(color: AppColors.redAccent, fontSize: 14)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, String sub, Color color) {
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
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) {
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
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}