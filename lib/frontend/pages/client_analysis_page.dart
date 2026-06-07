// import 'package:churn_v1/frontend/constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import '../models/chat_message.dart.dart';
// import '../components/client_header.dart';
// import '../components/risk_summary_card.dart';
// import '../components/client_info_card.dart';
// import '../components/chat_section.dart';
// import '../components/risk_history_chart.dart';

// class ClientAnalysisPage extends StatelessWidget {
//   final String clientName;
//   final String clientId;
//   final int riskPercent;
//   final String businessSize;
//   final String state;
//   final List<double> riskHistory;
//   final List<ChatMessage> chatMessages;

//   const ClientAnalysisPage({
//     super.key,
//     this.clientName = 'Juan Pérez',
//     this.clientId = 'A017',
//     this.riskPercent = 75,
//     this.businessSize = 'Mediana empresa',
//     this.state = 'Puebla',
//     this.riskHistory = const <double>[25, 30, 41, 50, 62, 75],
//     this.chatMessages = const [
//       ChatMessage(
//         text:
//             '¿Cuál ha sido el comportamiento de pago del cliente en los últimos 6 meses?',
//         isUser: true,
//         time: '10:30 AM',
//       ),
//       ChatMessage(
//         text:
//             'El cliente ha presentado 2 pagos tardíos en los últimos 6 meses, con un atraso promedio de 12 días.',
//         isUser: false,
//         time: '10:31 AM',
//       ),
//     ],
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             ClientHeader(name: clientName, id: clientId),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                 child: Column(
//                   children: [
//                     RiskSummaryCard(
//                       clientId: clientId,
//                       riskPercent: riskPercent,
//                     ),
//                     const SizedBox(height: 16),
//                     // IntrinsicHeight da una altura acotada a la fila para que
//                     // CrossAxisAlignment.stretch funcione dentro del scroll.
//                     IntrinsicHeight(
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Expanded(
//                             child: ClientInfoCard(
//                               icon: Icons.business_outlined,
//                               label: 'Tamaño de Negocio',
//                               value: businessSize,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: ClientInfoCard(
//                               icon: Icons.location_on_outlined,
//                               label: 'Estado de Residencia',
//                               value: state,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ChatSection(initialMessages: chatMessages),
//                     const SizedBox(height: 16),
//                     RiskHistoryChart(data: riskHistory),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:churn_v1/frontend/models/chat_message.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../models/client_detail.dart';
import '../models/chat_message.dart';

import '../components/client_header.dart';
import '../components/risk_summary_card.dart';
import '../components/client_info_card.dart';
import '../components/chat_section.dart';
import '../components/risk_history_chart.dart';

class ClientAnalysisPage extends StatefulWidget {
  final String clientId;
  const ClientAnalysisPage({super.key, required this.clientId});

  @override
  State<ClientAnalysisPage> createState() => _ClientAnalysisPageState();
}

class _ClientAnalysisPageState extends State<ClientAnalysisPage> {
  final ApiService _api = ApiService();
  ClientDetail? _detalle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final d = await _api.fetchDetalle(widget.clientId);
      setState(() {
        _detalle = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.redAccent))
            : _error != null
                ? _buildError()
                : _buildContent(_detalle!),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        ClientHeader(name: 'Cliente', id: widget.clientId),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar el cliente.\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ClientDetail d) {
    // Tendencia de actividad normalizada a 0-100 (proxy para la gráfica)
    final raw = [d.promedio6m, d.promedio3m, d.transUltimoMes];
    final maxV = raw.reduce((a, b) => a > b ? a : b);
    final serie = maxV <= 0
        ? <double>[0, 0, 0]
        : raw.map((v) => (v / maxV * 100).clamp(0.0, 100.0)).toList();

    // La narrativa de la IA por reglas se muestra como primer mensaje del chat
    final chat = [
      ChatMessage(
        text: d.narrativa.isNotEmpty
            ? d.narrativa
            : 'Pregúntame por qué este cliente está en riesgo.',
        isUser: false,
        time: '',
      ),
    ];

    return Column(
      children: [
        ClientHeader(name: 'Cliente', id: d.id),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                RiskSummaryCard(clientId: d.id, riskPercent: d.riskPercent),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClientInfoCard(
                          icon: Icons.business_outlined,
                          label: 'Tamaño de Negocio',
                          value: d.tamano,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClientInfoCard(
                          icon: Icons.location_on_outlined,
                          label: 'Territorio',
                          value: d.territorio,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ChatSection(
                  initialMessages: chat,
                  // ESTA es la conexión a Gemini:
                  onAsk: (pregunta) =>
                      _api.preguntar(pregunta, clienteId: d.id),
                ),
                const SizedBox(height: 16),
                RiskHistoryChart(
                  data: serie,
                  labels: const ['Prom 6m', 'Prom 3m', 'Último mes'],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}