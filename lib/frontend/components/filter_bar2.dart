import 'package:flutter/material.dart';
import '../constants/app_colors2.dart';

class FilterBar extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  const FilterBar({
    required this.selected,
    required this.options,
    required this.onChanged,
    required this.searchController,
    required this.onSearch,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por ID',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSecondary),
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
            color: AppColors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearch,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                dropdownColor: AppColors.surfaceAlt,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => v != null ? onChanged(v) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}