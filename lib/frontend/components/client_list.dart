import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/client.dart';

class ClientList extends StatelessWidget {
  final List<Client> clients;
  final void Function(Client) onTap;

  const ClientList({super.key, required this.clients, required this.onTap});

  Color _colorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'alto':
        return AppColors.redAccent;
      case 'medio':
        return AppColors.amber;
      default:
        return const Color(0xFF2ECC71); // verde para bajo
    }
  }

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 14)}…' : id;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay clientes para este filtro.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: clients.length,
      itemBuilder: (_, i) {
        final c = clients[i];
        final color = _colorNivel(c.nivelRiesgo);
        return GestureDetector(
          onTap: () => onTap(c),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shortId(c.id),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Riesgo ${c.nivelRiesgo}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${c.risk}%',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}