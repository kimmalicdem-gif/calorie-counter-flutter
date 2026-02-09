import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Placeholder for calorie limits
  int _minCal = 1900;
  int _maxCal = 2100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calorie Intake Limit', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _minCal.toString(),
                    decoration: const InputDecoration(labelText: 'Min'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _minCal = int.tryParse(v) ?? _minCal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _maxCal.toString(),
                    decoration: const InputDecoration(labelText: 'Max'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _maxCal = int.tryParse(v) ?? _maxCal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete),
              label: const Text('Clear Calendar (History)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}