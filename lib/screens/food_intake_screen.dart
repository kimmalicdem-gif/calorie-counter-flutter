import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/food_database.dart';
import '../models/calorie_entry.dart';
import '../services/storage_service.dart';
import 'widgets/period_selector.dart';
import 'widgets/food_selector.dart';
import 'widgets/entry_list.dart';
import '../services/calorie_limit_service.dart';

class FoodIntakeScreen extends StatefulWidget {
  final FoodDatabase foodDatabase;
  final bool isDayMode;

  const FoodIntakeScreen({
    Key? key,
    required this.foodDatabase,
    required this.isDayMode,
  }) : super(key: key);

  @override
  State<FoodIntakeScreen> createState() => _FoodIntakeScreenState();
}

class _FoodIntakeScreenState extends State<FoodIntakeScreen> {
  late FoodDatabase _foodDatabase;
  late StorageService _storageService;
  List<CalorieEntry> _allEntries = [];
  String? _selectedPeriod;
  String? _selectedCategory;
  Food? _selectedFood;
  int _quantity = 1;
  bool _isLoading = true;
  int _minTarget = 1900;
  int _maxTarget = 2100;
  DateTime _selectedDate = DateTime.now();
  bool _isToday = true;

  List<CalorieEntry> get _filteredEntries {
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _allEntries.where((entry) {
      final entryDay = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      return entryDay.isAtSameMomentAs(selectedDay);
    }).toList();
  }

  int get _totalCalories => _filteredEntries.fold(0, (sum, e) => sum + e.calories);
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
      _allEntries = _storageService.getEntries();
      _isLoading = false;
    });
  }

  void _updateDateFilter() {
    setState(() {
      // Trigger rebuild with new filtered entries
    });
  }

  List<BarChartGroupData> _getSevenDayChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<BarChartGroupData> groups = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      
      // Calculate total calories from actual entries for this date
      double totalCalories = 0.0;
      for (var entry in _allEntries) {
        final entryDay = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        if (entryDay.isAtSameMomentAs(date)) {
          totalCalories += entry.calories;
        }
      }
      
      final barIndex = 6 - i;
      groups.add(
        BarChartGroupData(
          x: barIndex,
          barRods: [
            BarChartRodData(
              toY: totalCalories,
              color: Colors.blue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  Widget _buildSevenDayChart() {
    final groups = _getSevenDayChartData();
    final maxY = groups.isNotEmpty 
        ? groups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 2500.0;
    
    // Calculate which bar represents the selected date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final daysDiff = today.difference(selectedDay).inDays;
    final selectedBarIndex = 6 - daysDiff; // 0-6 range

    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;

    return Card(
      elevation: 3,
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Calorie Intake',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fgColor),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final date = today.subtract(Duration(days: (6 - value.toInt())));
                          final dateStr = '${date.month}/${date.day}';
                          final isCenterDate = value.toInt() == selectedBarIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: isCenterDate ? 13 : 11,
                                fontWeight: isCenterDate ? FontWeight.bold : FontWeight.normal,
                                color: fgColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(fontSize: 10, color: fgColor),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final pct = _maxTarget == 0 ? 0 : _totalCalories / _maxTarget;
    final color = _colorFromStatus(_statusColor);
    final bgColor = color.withOpacity(0.2);
    final textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    String dateLabel;
    if (_isToday) {
      dateLabel = "Today's Stats";
    } else {
      dateLabel = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: color, size: 28),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calorie Intake',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Consumed: $_totalCalories kcal",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
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
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            SizedBox(height: 12),
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

  Widget _buildDateSelector() {
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entry Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Today'),
                    selected: _isToday,
                    onSelected: (selected) {
                      setState(() {
                        _isToday = true;
                        _selectedDate = DateTime.now();
                      });
                      _updateDateFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Pick Date'),
                    selected: !_isToday,
                    onSelected: (selected) async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _isToday = false;
                          _selectedDate = pickedDate;
                        });
                        _updateDateFilter();
                      }
                    },
                  ),
                ),
              ],
            ),
            if (!_isToday) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      timestamp: _isToday ? DateTime.now() : _selectedDate,
    );

    _storageService.addEntry(entry).then((_) {
      setState(() {
        _allEntries = _storageService.getEntries();
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
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade800;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('Delete Entry', style: TextStyle(color: fgColor)),
        content: Text('Are you sure you want to delete this entry?', style: TextStyle(color: fgColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: fgColor)),
          ),
          TextButton(
            onPressed: () {
              _storageService.removeEntry(id).then((_) {
                setState(() {
                  _allEntries = _storageService.getEntries();
                });
                Navigator.of(context).pop();
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
              const SizedBox(height: 16),
              // 7-Day Chart
              _buildSevenDayChart(),
              const SizedBox(height: 24),
              // Today's Stats
              _buildStatusCard(),
              const SizedBox(height: 24),
              // Date Selector
              _buildDateSelector(),
              const SizedBox(height: 16),
              // Period Selector
              PeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodSelected: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
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
                  setState(() {
                    _selectedFood = food;
                  });
                },
                isDayMode: widget.isDayMode,
              ),
              const SizedBox(height: 16),
              // Quantity Input
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
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
              // Add Entry Button
              ElevatedButton.icon(
                onPressed: _addEntry,
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
              const SizedBox(height: 24),
              // Entry List
              EntryList(
                entries: _filteredEntries,
                onDelete: _deleteEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
