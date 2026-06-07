// class Client {
//   final String id;
//   final int risk;

//   Client({
//     required this.id,
//     required this.risk,
//   });
// }


class Client {
  final String id;
  final int risk;            // 0-100 (probabilidad de churn en %)
  final String nivelRiesgo;  // 'alto' | 'medio' | 'bajo'
  final String businessSize; // tamaño de negocio
  final String state;        // territorio / estado
 
  const Client({
    required this.id,
    required this.risk,
    this.nivelRiesgo = 'bajo',
    this.businessSize = 'Desconocido',
    this.state = 'Desconocido',
  });
 
  // Mapea la respuesta de GET /clientes y GET /buscar (ClienteResumen)
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['customer_id']?.toString() ?? '',
      risk: (((json['probabilidad_churn'] ?? 0) as num) * 100).round(),
      nivelRiesgo: json['riesgo']?.toString() ?? 'bajo',
      businessSize: json['tamano']?.toString() ?? 'Desconocido',
      state: json['territorio']?.toString() ?? 'Desconocido',
    );
  }
}
 