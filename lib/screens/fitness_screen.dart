import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/calorie_burn_service.dart';

class FitnessScreen extends StatefulWidget {
  final bool isDayMode;

  const FitnessScreen({
    Key? key,
    required this.isDayMode,
  }) : super(key: key);

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  late StorageService _storageService;
  List<Activity> _allActivities = [];
  bool _isLoading = true;
  UserProfile? _profile;
  DateTime _selectedDate = DateTime.now();
  bool _isToday = true;

  List<Activity> get _filteredActivities {
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _allActivities.where((activity) {
      final activityDay = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );
      return activityDay.isAtSameMomentAs(selectedDay);
    }).toList();
  }

  int get _totalMinutes =>
      _filteredActivities.fold(0, (sum, a) => sum + a.duration);
  
  double get _totalCaloriesBurned =>
      _filteredActivities.fold(0.0, (sum, a) => sum + (a.caloriesBurned ?? 0.0));

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _storageService.init();
    final profile = _storageService.getProfile();
    final allActivities = _storageService.getActivities();

    setState(() {
      _profile = profile;
      _allActivities = allActivities;
      _isLoading = false;
    });
  }

  void _updateDateFilter() {
    setState(() {
      // Trigger rebuild with new filtered activities
    });
  }

  List<BarChartGroupData> _getSevenDayChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<BarChartGroupData> groups = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      double totalMinutes = 0.0;

      // Calculate from cached activities
      for (var activity in _allActivities) {
        final activityDate = DateTime(
          activity.timestamp.year,
          activity.timestamp.month,
          activity.timestamp.day,
        );
        if (activityDate.isAtSameMomentAs(date)) {
          totalMinutes += activity.duration;
        }
      }

      final barIndex = 6 - i;
      groups.add(
        BarChartGroupData(
          x: barIndex,
          barRods: [
            BarChartRodData(
              toY: totalMinutes,
              color: Colors.green,
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
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

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
              '7-Day Activity Minutes',
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
                            '${value.toInt()}m',
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

  Widget _buildTodaySummary() {
    String dateLabel;
    if (_isToday) {
      dateLabel = "Today's Summary";
    } else {
      dateLabel = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    }

    return Card(
      elevation: 3,
      color: Colors.green.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Minutes',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$_totalMinutes min',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Calories Burned',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_totalCaloriesBurned.toStringAsFixed(1)} kcal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isToday = true;
                _selectedDate = DateTime.now();
              });
              _updateDateFilter();
            },
            icon: Icon(Icons.calendar_today),
            label: Text('Today'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isToday ? Colors.blue : Colors.grey.shade300,
              foregroundColor: _isToday ? Colors.white : Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
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
            icon: Icon(Icons.date_range),
            label: Text('Pick Date'),
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isToday ? Colors.blue : Colors.grey.shade300,
              foregroundColor: !_isToday ? Colors.white : Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDurationDialog(String activityName, Color activityColor, IconData activityIcon) async {
    if (_profile == null || _profile!.weight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set your weight in Profile Settings first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TextEditingController controller = TextEditingController(text: '30');
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade800;
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Row(
          children: [
            Icon(activityIcon, color: activityColor),
            SizedBox(width: 8),
            Expanded(child: Text('How many minutes?', style: TextStyle(color: fgColor))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activityName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: fgColor),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: fgColor),
              decoration: InputDecoration(
                labelText: 'Duration (minutes)',
                labelStyle: TextStyle(color: fgColor.withOpacity(0.7)),
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: fgColor)),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.pop(context, minutes);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: activityColor),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      _addActivityFromBlock(activityName, result);
    }
  }

  void _addActivityFromBlock(String activityName, int minutes) {
    final caloriesBurned = CalorieBurnService.calculateCaloriesBurned(
      activityName: activityName,
      durationMinutes: minutes,
      weightKg: _profile!.weight,
    );

    final activity = Activity(
      id: Uuid().v4(),
      name: activityName,
      duration: minutes,
      timestamp: _isToday ? DateTime.now() : _selectedDate,
      caloriesBurned: caloriesBurned,
    );

    _storageService.addActivity(activity).then((_) {
      setState(() {
        _allActivities = _storageService.getActivities();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${activityName} added: $minutes min, ${caloriesBurned.toStringAsFixed(1)} cal'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  Widget _buildActivityBlock({
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _showDurationDialog(name, color, icon),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(height: 12),
            Text(
              name.split('(')[0].trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteActivity(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _storageService.removeActivity(id).then((_) {
                setState(() {
                  _allActivities = _storageService.getActivities();
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

    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header
              Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.blue, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Daily Activities',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 7-Day Chart
              _buildSevenDayChart(),
              const SizedBox(height: 24),
              
              // Today's Summary Card
              Card(
                elevation: 4,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isToday ? "Today's Summary" : "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Total Activities',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_filteredActivities.length}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$_totalMinutes min • ${_totalCaloriesBurned.toStringAsFixed(1)} cal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      // Activity List
                      if (_filteredActivities.isNotEmpty) ...[
                        SizedBox(height: 16),
                        ..._filteredActivities.map((activity) => Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${activity.name.split('(')[0].trim()} • ${activity.duration} min',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${activity.caloriesBurned?.toStringAsFixed(1) ?? '0'} cal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _deleteActivity(activity.id),
                                    child: Icon(Icons.close, size: 20, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Date Selector
              _buildDateSelector(),
              
              const SizedBox(height: 24),
              
              // Available Activities Header
              Text(
                'Available Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Activity Blocks Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildActivityBlock(
                    name: 'Walking (5–5.5 km/h)',
                    icon: Icons.directions_walk,
                    color: Colors.green.shade700,
                  ),
                  _buildActivityBlock(
                    name: 'Running (8 km/h jog)',
                    icon: Icons.directions_run,
                    color: Colors.red.shade700,
                  ),
                  _buildActivityBlock(
                    name: 'Home Workout (bodyweight, steady)',
                    icon: Icons.sports_gymnastics,
                    color: Colors.orange.shade700,
                  ),
                  _buildActivityBlock(
                    name: 'Gym (moderate resistance training)',
                    icon: Icons.fitness_center,
                    color: Colors.purple.shade700,
                  ),
                  _buildActivityBlock(
                    name: 'Sports (moderate, recreational)',
                    icon: Icons.sports_soccer,
                    color: Colors.blue.shade700,
                  ),
                  _buildActivityBlock(
                    name: 'Cycling (16–19 km/h)',
                    icon: Icons.directions_bike,
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
