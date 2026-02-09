import 'package:flutter/material.dart';
import '../../models/calorie_entry.dart';

class EntryList extends StatelessWidget {
  final List<CalorieEntry> entries;
  final Function(String) onDelete;

  const EntryList({
    Key? key,
    required this.entries,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _getPeriodColor(entry.period),
              ),
            ),
            title: Text(entry.food),
            subtitle: Text(
              '${entry.period} • ${entry.calories} kcal',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDelete(entry.id),
            ),
          ),
        );
      },
    );
  }

  Color _getPeriodColor(String period) {
    switch (period) {
      case 'AM':
        return Colors.orange;
      case 'PM':
        return Colors.blue;
      case 'Night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
