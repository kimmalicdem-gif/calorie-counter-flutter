import 'package:flutter/material.dart';
import '../../models/calorie_entry.dart';

class StatusCard extends StatelessWidget {
  final int totalCalories;
  final String statusColor;

  const StatusCard({
    Key? key,
    required this.totalCalories,
    required this.statusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const minTarget = 1900;
    const maxTarget = 2100;
    final remaining = (maxTarget - totalCalories).clamp(0, maxTarget);

    Color cardColor;
    Color textColor;
    String statusText;

    switch (statusColor) {
      case 'green':
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusText = 'Keep going! 💪';
        break;
      case 'yellow':
        cardColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        statusText = 'On target! 🎯';
        break;
      case 'red':
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        statusText = 'Over target ⚠️';
        break;
      default:
        cardColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        statusText = '';
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Consumed: $totalCalories kcal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: $remaining kcal',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (totalCalories / 2100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
