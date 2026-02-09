import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({Key? key}) : super(key: key);

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {

  int _minCal = 1900;
  int _maxCal = 2100;
  bool _loading = true;

  // ...existing code...
  static const String _minKey = 'minCalorieLimit';
  static const String _maxKey = 'maxCalorieLimit';

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _minCal = prefs.getInt(_minKey) ?? 1900;
      _maxCal = prefs.getInt(_maxKey) ?? 2100;
      _loading = false;
    });
  }

  Future<void> _saveLimits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minKey, _minCal);
    await prefs.setInt(_maxKey, _maxCal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calorie limits saved!')),
      );
    }
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveLimits,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
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
