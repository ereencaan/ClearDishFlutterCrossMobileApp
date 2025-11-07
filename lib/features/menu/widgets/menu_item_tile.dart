import 'package:flutter/material.dart';
import 'package:cleardish/data/models/menu_item.dart';

/// Menu item tile widget
/// 
/// Displays a menu item with its details.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    required this.item,
    super.key,
  });

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (item.price != null)
                  Text(
                    '\$${item.price!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (item.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.allergens.map((allergen) {
                  return Chip(
                    label: Text(
                      allergen,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


