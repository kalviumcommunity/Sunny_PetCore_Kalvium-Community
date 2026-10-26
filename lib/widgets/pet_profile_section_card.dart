import 'package:flutter/material.dart';

class PetProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final String emptyMessage;
  final List<Widget> items;

  const PetProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    required this.emptyMessage,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text('$count'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 16),
            if (visibleItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...visibleItems,
          ],
        ),
      ),
    );
  }
}
