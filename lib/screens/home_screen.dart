
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/food_database.dart';
import '../models/calorie_entry.dart';
import '../services/storage_service.dart';
import 'widgets/period_selector.dart';
import 'widgets/food_selector.dart';
import 'widgets/entry_list.dart';
import 'widgets/status_card.dart';
import '../services/calorie_limit_service.dart';

class HomeScreen extends StatefulWidget {
  final FoodDatabase foodDatabase;
  final bool isDayMode;
  HomeScreen({Key? key, required this.foodDatabase, required this.isDayMode}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FoodDatabase _foodDatabase;
  late StorageService _storageService;
  List<CalorieEntry> _entries = [];
  String? _selectedPeriod;
  String? _selectedCategory;
  Food? _selectedFood;
  int _quantity = 1;
  bool _isLoading = true;
  int _minTarget = 1900;
  int _maxTarget = 2100;
  // Remove local _isDayMode, use widget.isDayMode

  int get _totalCalories => _entries.fold(0, (sum, e) => sum + e.calories);
  int get _remaining => (_maxTarget - _totalCalories).clamp(0, _maxTarget);
  String get _statusColor {
    double pct = _maxTarget == 0 ? 0 : _totalCalories / _maxTarget;
    if (pct <= 0.6) return 'green';
    if (pct <= 0.9) return 'orange';
    return 'red';
  }
  String get _statusText {
    double pct = _maxTarget == 0 ? 0 : _totalCalories / _maxTarget;
    if (pct <= 0.6) return "Below target";
    if (pct <= 0.9) return "Normal";
    return "Over target △";
  }
  Color _colorFromStatus(String status) {
    switch (status) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  @override
  void initState() {
    super.initState();
    _foodDatabase = widget.foodDatabase;
    _storageService = StorageService();
    _initializeApp();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTargets();
  }
  Future<void> _loadTargets() async {
    final min = await CalorieLimitService.getMin();
    final max = await CalorieLimitService.getMax();
    setState(() {
      _minTarget = min;
      _maxTarget = max;
    });
  }
  Future<void> _initializeApp() async {
    await _storageService.init();
    if (!_foodDatabase.isLoaded) {
      await _foodDatabase.loadFoods();
    }
    setState(() {
      _entries = _storageService.getEntries();
      _isLoading = false;
    });
  }
  Widget _buildStatusCard() {
    final pct = _maxTarget == 0 ? 0 : _totalCalories / _maxTarget;
    final color = _colorFromStatus(_statusColor);
    final bgColor = color.withOpacity(0.2);
    final textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Consumed: $_totalCalories kcal",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Remaining: $_remaining kcal",
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            SizedBox(height: 8),
            Text(
              _statusText,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct.clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
  void _addEntry() {
    if (_selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a period.')),
      );
      return;
    }
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a food.')),
      );
      return;
    }
    final entry = CalorieEntry(
      id: Uuid().v4(),
      period: _selectedPeriod!,
      food: _quantity > 1
          ? "${_selectedFood!.name} (${_quantity}x)"
          : _selectedFood!.name,
      calories: _selectedFood!.calories * _quantity,
      timestamp: DateTime.now(),
    );
    _storageService.addEntry(entry).then((_) {
      setState(() {
        _entries = _storageService.getEntries();
        _selectedFood = null;
        _selectedCategory = null;
        _selectedPeriod = null;
        _quantity = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry added successfully!')),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _storageService.removeEntry(id).then((_) {
                setState(() {
                  _entries = _storageService.getEntries();
                });
                Navigator.of(context).pop();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final mediaQuery = MediaQuery.of(context);
    final topSpacing = mediaQuery.size.height * 0.05;
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topSpacing < 32 ? 32 : topSpacing),
              // Day/Night mode ticker
              // Removed Day/Night mode ticker from HomeScreen
              _buildStatusCard(),
              const SizedBox(height: 24),
              PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodSelected: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
              ),
              const SizedBox(height: 16),
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
                  setState(() {
                    _selectedFood = food;
                  });
                },
                isDayMode: widget.isDayMode,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Quantity:', style: TextStyle(color: fgColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _quantity.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        fillColor: bgColor,
                        filled: true,
                        hintStyle: TextStyle(color: fgColor.withOpacity(0.6)),
                      ),
                      style: TextStyle(color: fgColor),
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        setState(() {
                          _quantity = (val != null && val > 0) ? val : 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
              const SizedBox(height: 24),
              EntryList(
                entries: _entries,
                onDelete: _deleteEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
