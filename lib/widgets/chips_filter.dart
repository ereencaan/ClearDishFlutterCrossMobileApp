import 'package:flutter/material.dart';

/// Chips filter widget for multi-select items
/// 
/// Displays selectable chips with clear functionality.
class ChipsFilter extends StatelessWidget {
  const ChipsFilter({
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    this.label,
    this.showClearButton = true,
    super.key,
  });

  final List<String> items;
  final List<String> selectedItems;
  final void Function(List<String>) onSelectionChanged;
  final String? label;
  final bool showClearButton;

  void _toggleItem(String item) {
    final newSelection = List<String>.from(selectedItems);
    if (newSelection.contains(item)) {
      newSelection.remove(item);
    } else {
      newSelection.add(item);
    }
    onSelectionChanged(newSelection);
  }

  void _clearSelection() {
    onSelectionChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (showClearButton && selectedItems.isNotEmpty)
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              selected: isSelected,
              label: Text(item),
              onSelected: (_) => _toggleItem(item),
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(
                    0.3,
                  ),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


