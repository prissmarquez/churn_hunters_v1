import 'package:flutter/material.dart';
import '../constants/app_colors2.dart';

class ClientHeader extends StatelessWidget {
  final String name;
  final String id;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const ClientHeader({
    required this.name,
    required this.id,
    this.onBack,
    this.onMenu,
    super.key,
  });

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 20),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.bubbleOut,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: $id',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: onMenu ?? () {},
          ),
        ],
      ),
    );
  }
}