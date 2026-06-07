import 'package:flutter/material.dart';

import '../constants/app_colors2.dart';
import '../models/chat_message2.dart';
import '../components/client_header2.dart';
import '../components/risk_summary_card2.dart';
import '../components/client_info_card2.dart';
import '../components/chat_section2.dart';
import '../components/risk_history_chart2.dart';

class RiskDashboardPage extends StatelessWidget {
  final String clientName;
  final String clientId;
  final int riskPercent;
  final String businessSize;
  final String state;
  final List<double> riskHistory;
  final List<ChatMessage> chatMessages;

  const RiskDashboardPage({
    super.key,
    this.clientName = 'Juan Pérez',
    this.clientId = 'A017',
    this.riskPercent = 75,
    this.businessSize = 'Mediana empresa',
    this.state = 'Puebla',
    this.riskHistory = const <double>[25, 30, 41, 50, 62, 75],
    this.chatMessages = const [
      ChatMessage(
        text:
            '¿Cuál ha sido el comportamiento de pago del cliente en los últimos 6 meses?',
        isUser: true,
        time: '10:30 AM',
      ),
      ChatMessage(
        text:
            'El cliente ha presentado 2 pagos tardíos en los últimos 6 meses, con un atraso promedio de 12 días.',
        isUser: false,
        time: '10:31 AM',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ClientHeader(name: clientName, id: clientId),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    RiskSummaryCard(
                      clientId: clientId,
                      riskPercent: riskPercent,
                    ),
                    const SizedBox(height: 16),
                    // IntrinsicHeight da una altura acotada a la fila para que
                    // CrossAxisAlignment.stretch funcione dentro del scroll.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClientInfoCard(
                              icon: Icons.business_outlined,
                              label: 'Tamaño de Negocio',
                              value: businessSize,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClientInfoCard(
                              icon: Icons.location_on_outlined,
                              label: 'Estado de Residencia',
                              value: state,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChatSection(initialMessages: chatMessages),
                    const SizedBox(height: 16),
                    RiskHistoryChart(data: riskHistory),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}