import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  final String? selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  const PeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'label': 'AM', 'emoji': '🌅'},
      {'label': 'PM', 'emoji': '☀️'},
      {'label': 'Night', 'emoji': '🌙'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When did you eat?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: periods.map((period) {
            final isSelected = selectedPeriod == period['label'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text('${period['emoji']} ${period['label']}'),
                  selected: isSelected,
                  onSelected: (_) => onPeriodSelected(period['label']!),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
