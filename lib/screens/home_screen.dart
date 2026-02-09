import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/food_database.dart';
import '../models/calorie_entry.dart';
import '../services/storage_service.dart';
import 'widgets/period_selector.dart';
import 'widgets/food_selector.dart';
import 'widgets/entry_list.dart';
import 'widgets/status_card.dart';
import 'widgets/bottom_sheet_new_day.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FoodDatabase _foodDatabase = FoodDatabase();
  final StorageService _storageService = StorageService();
  
  late List<CalorieEntry> _entries;
  String? _selectedPeriod;
  String? _selectedCategory;
  Food? _selectedFood;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _storageService.init();
    await _foodDatabase.loadFoods();
    setState(() {
      _entries = _storageService.getEntries();
      _isLoading = false;
    });
  }

  int get _totalCalories {
    return _entries.fold(0, (sum, entry) => sum + entry.calories);
  }

  String get _statusColor {
    if (_totalCalories < 1900) return 'green';
    if (_totalCalories <= 2100) return 'yellow';
    return 'red';
  }

  void _addEntry() {
    if (_selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a period (AM/PM/Night)')),
      );
      return;
    }

    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food')),
      );
      return;
    }

    final entry = CalorieEntry(
      id: const Uuid().v4(),
      period: _selectedPeriod!,
      food: _selectedFood!.name,
      calories: _selectedFood!.calories,
      timestamp: DateTime.now(),
    );

    _storageService.addEntry(entry).then((_) {
      setState(() {
        _entries = _storageService.getEntries();
        _selectedFood = null;
        _selectedCategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry added successfully!')),
      );
    });
  }

  void _deleteEntry(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _storageService.removeEntry(id).then((_) {
                setState(() {
                  _entries = _storageService.getEntries();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entry deleted')),
                );
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNewDayDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheetNewDay(
        totalCalories: _totalCalories,
        onConfirm: (weight) async {
          await _storageService.saveDaySummary(_totalCalories, weight: weight);
          await _storageService.clearEntries();
          setState(() {
            _entries = [];
            _selectedPeriod = null;
            _selectedCategory = null;
            _selectedFood = null;
          });
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New day started!')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calorie Counter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽️ Calorie Counter'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Daily Target',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1900 - 2100 kcal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Period Selector
              PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodSelected: (period) {
                  setState(() => _selectedPeriod = period);
                },
              ),
              const SizedBox(height: 16),

              // Food Selector
              FoodSelector(
                foodDatabase: _foodDatabase,
                selectedCategory: _selectedCategory,
                selectedFood: _selectedFood,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedFood = null;
                  });
                },
                onFoodChanged: (food) {
                  setState(() => _selectedFood = food);
                },
              ),
              const SizedBox(height: 16),

              // Add Entry Button
              ElevatedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Status Card
              StatusCard(
                totalCalories: _totalCalories,
                statusColor: _statusColor,
              ),
              const SizedBox(height: 16),

              // Entry List
              if (_entries.isNotEmpty) ...[
                const Text(
                  'Today\'s Entries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                EntryList(
                  entries: _entries,
                  onDelete: _deleteEntry,
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No entries yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // New Day Button
              ElevatedButton.icon(
                onPressed: _showNewDayDialog,
                icon: const Icon(Icons.refresh),
                label: const Text('New Day'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
