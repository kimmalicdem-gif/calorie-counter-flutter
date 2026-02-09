import 'package:flutter/material.dart';

class BottomSheetNewDay extends StatefulWidget {
  final int totalCalories;
  final Function(double?) onConfirm;

  const BottomSheetNewDay({
    Key? key,
    required this.totalCalories,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BottomSheetNewDay> createState() => _BottomSheetNewDayState();
}

class _BottomSheetNewDayState extends State<BottomSheetNewDay> {
  final TextEditingController _weightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Start New Day',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Today\'s total: ${widget.totalCalories} kcal',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (kg) - Optional',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final weight = _weightController.text.isNotEmpty
                        ? double.tryParse(_weightController.text)
                        : null;
                    widget.onConfirm(weight);
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }
}
