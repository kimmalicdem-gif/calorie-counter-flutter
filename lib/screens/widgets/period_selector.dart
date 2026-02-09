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
      {'label': 'AM', 'icon': Icons.wb_twighlight},
      {'label': 'PM', 'icon': Icons.wb_sunny},
      {'label': 'Night', 'icon': Icons.nights_stay},
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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(period['icon'] as IconData, size: 22, color: isSelected ? Colors.white : Colors.grey),
                      const SizedBox(width: 8),
                      Text(period['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => onPeriodSelected(period['label'] as String),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
