import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FilterBar extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const FilterBar({
    super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
    required this.searchController,
    required this.onSearch,
    required this.selectedSort,
    required this.onSortChanged,
  });

  static const sortOptions = [
    _SortOption('riesgo_desc', 'Mayor riesgo primero ↓'),
    _SortOption('riesgo_asc',  'Menor riesgo primero ↑'),
    _SortOption('estado_az',   'Estado A → Z'),
    _SortOption('estado_za',   'Estado Z → A'),
    _SortOption('id_az',       'ID Alfabético A → Z'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Búsqueda por ID ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: whiteColor),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por ID',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: redColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: whiteColor),
                onPressed: onSearch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Filtro por nivel de riesgo ─────────────────────────────────
        _dropdown(
          value: selected,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
          prefix: const Icon(Icons.flag_outlined,
              color: AppColors.textSecondary, size: 16),
        ),
        const SizedBox(height: 8),

        // ── Ordenamiento ───────────────────────────────────────────────
        _dropdown(
          value: selectedSort,
          items: sortOptions
              .map((o) => DropdownMenuItem(value: o.key, child: Text(o.label)))
              .toList(),
          onChanged: (v) { if (v != null) onSortChanged(v); },
          prefix: const Icon(Icons.sort, color: AppColors.textSecondary, size: 16),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    Widget? prefix,
  }) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix, const SizedBox(width: 8)],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: cardColor,
                iconEnabledColor: whiteColor,
                isExpanded: true,
                style: const TextStyle(color: whiteColor, fontSize: 13),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption {
  final String key;
  final String label;
  const _SortOption(this.key, this.label);
}
