class RiskFactor {
  final String descripcion;
  final String severidad; // 'alta' | 'media' | 'baja'
  const RiskFactor({required this.descripcion, required this.severidad});

  factory RiskFactor.fromJson(Map<String, dynamic> j) => RiskFactor(
        descripcion: j['descripcion']?.toString() ?? '',
        severidad: j['severidad']?.toString() ?? 'baja',
      );
}

class ClientDetail {
  final String id;
  final String territorio;
  final String subcanal;
  final String tamano;

  final double probabilidad; // 0-1
  final int riskPercent;     // 0-100
  final String nivel;        // alto/medio/bajo
  final String narrativa;    // explicación lista para mostrar
  final List<RiskFactor> factores;

  // features_clave
  final double transUltimoMes;
  final double promedio3m;
  final double promedio6m;
  final double tendencia;
  final double mesesActivos3m;
  final double coolersPromedio;

  final String featuresModelo; // drivers del modelo (SHAP) si vienen

  const ClientDetail({
    required this.id,
    required this.territorio,
    required this.subcanal,
    required this.tamano,
    required this.probabilidad,
    required this.riskPercent,
    required this.nivel,
    required this.narrativa,
    required this.factores,
    required this.transUltimoMes,
    required this.promedio3m,
    required this.promedio6m,
    required this.tendencia,
    required this.mesesActivos3m,
    required this.coolersPromedio,
    required this.featuresModelo,
  });

  factory ClientDetail.fromJson(Map<String, dynamic> j) {
    final expl = (j['explicacion'] ?? {}) as Map<String, dynamic>;
    final fc = (j['features_clave'] ?? {}) as Map<String, dynamic>;
    final prob = ((expl['probabilidad'] ?? 0) as num).toDouble();
    double n(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    return ClientDetail(
      id: j['customer_id']?.toString() ?? '',
      territorio: j['territorio']?.toString() ?? 'Desconocido',
      subcanal: j['subcanal']?.toString() ?? 'Desconocido',
      tamano: j['tamano']?.toString() ?? 'Desconocido',
      probabilidad: prob,
      riskPercent: (prob * 100).round(),
      nivel: expl['nivel']?.toString() ?? 'bajo',
      narrativa: expl['narrativa']?.toString() ?? '',
      factores: ((expl['factores'] ?? []) as List)
          .map((e) => RiskFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
      transUltimoMes: n(fc['transacciones_ultimo_mes']),
      promedio3m: n(fc['promedio_3m']),
      promedio6m: n(fc['promedio_6m']),
      tendencia: n(fc['tendencia']),
      mesesActivos3m: n(fc['meses_activos_3m']),
      coolersPromedio: n(fc['coolers_promedio']),
      featuresModelo: j['features_influyentes_modelo']?.toString() ?? '',
    );
  }
}