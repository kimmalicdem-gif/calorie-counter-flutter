import '../services/calorie_limit_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calorie_entry.dart';
import '../models/activity.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final bool isDayMode;
  const HistoryScreen({Key? key, required this.isDayMode}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class DayData {
  final DaySummary? summary;
  final bool hasFoodIntake;
  final bool hasFitness;
  
  DayData({
    this.summary,
    required this.hasFoodIntake,
    required this.hasFitness,
  });
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  Color _contrastColor(Color c) => c.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  late DateTime _selectedMonth;
  late List<DaySummary> _history;
  List<CalorieEntry> _allEntries = [];
  List<Activity> _allActivities = [];
  int _maxTarget = 2100;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _history = [];
    _loadData();
  }

  Future<void> _loadData() async {
    await _storageService.init();
    final entries = _storageService.getEntries();
    final activities = _storageService.getActivities();
    setState(() {
      _allEntries = entries;
      _allActivities = activities;
    });
  }

  void _refreshHistory() {
    setState(() {
      _history = _storageService.getHistory();
      _allEntries = _storageService.getEntries();
      _allActivities = _storageService.getActivities();
    });
  }

  Map<String, DayData> _getDaysInMonth() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    Map<String, DayData> days = {};
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    int todayTotal = 0;
    if (_selectedMonth.year == today.year && _selectedMonth.month == today.month) {
      // Get today's total from current entries
      todayTotal = _allEntries.fold(0, (sum, entry) => sum + entry.calories);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, i);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      DaySummary? summary = _history.firstWhere(
        (h) => h.date == dateStr,
        orElse: () => DaySummary(date: dateStr, totalCalories: 0),
      );
      
      // If today, use live total
      if (dateStr == todayStr) {
        summary = DaySummary(date: dateStr, totalCalories: todayTotal);
      }
      
      // Check if has food intake for this date
      final hasFoodIntake = _allEntries.any((entry) {
        final entryDateStr = DateFormat('yyyy-MM-dd').format(entry.timestamp);
        return entryDateStr == dateStr;
      });
      
      // Check if has fitness data for this date
      final hasFitness = _allActivities.any((activity) {
        final activityDateStr = DateFormat('yyyy-MM-dd').format(activity.timestamp);
        return activityDateStr == dateStr;
      });
      
      days[dateStr] = DayData(
        summary: summary.totalCalories > 0 ? summary : null,
        hasFoodIntake: hasFoodIntake,
        hasFitness: hasFitness,
      );
    }
    return days;
  }

  String _getStatusText(int calories) {
    if (calories < 1900) return 'Low';
    if (calories <= 2100) return 'On Target';
    return 'Over';
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshHistory();
    _loadMaxTarget();
  }

  Future<void> _loadMaxTarget() async {
    final max = await CalorieLimitService.getMax();
    setState(() {
      _maxTarget = max;
    });
  }

  Color _getStatusColor(int calories) {
    if (_maxTarget == 0) return Colors.grey;
    double pct = calories / _maxTarget;
    if (pct <= 0.6) return Colors.green;
    if (pct <= 0.9) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusBgColor(int calories) {
    if (_maxTarget == 0) return Colors.grey.shade200;
    double pct = calories / _maxTarget;
    if (pct <= 0.6) return Colors.green.shade50;
    if (pct <= 0.9) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
      ),
      body: Container(
        color: bgColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Day/Night mode ticker
                // Removed Day/Night mode ticker from HistoryScreen
                // Month Navigation
                Card(
                  color: bgColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          color: fgColor,
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                            _refreshHistory();
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fgColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          color: fgColor,
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                            _refreshHistory();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Days Tracked',
                        days.values.where((d) => d.hasFoodIntake || d.hasFitness).length.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Calories',
                        _calculateAverageCalories(days).toString(),
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final dayNumber = index - (firstDayWeekday - 1) + 1;
                    if (dayNumber <= 0 || dayNumber > daysInMonth) {
                      return const SizedBox();
                    }
                    final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                    final dateStr = DateFormat('yyyy-MM-dd').format(date);
                    final dayData = days[dateStr];
                    return GestureDetector(
                      onTap: () {
                        if (dayData != null && (dayData.hasFoodIntake || dayData.hasFitness)) {
                          _showDayDetail(date, dateStr);
                        }
                      },
                      child: _buildDayCard(dayData, dayNumber),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Recent Days List
                if (_history.isNotEmpty) ...[
                  const Text(
                    'Recent Days',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length > 7 ? 7 : _history.length,
                    itemBuilder: (context, index) {
                      final summary = _history[_history.length - 1 - index];
                      return _buildRecentDayTile(summary);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(DayData? dayData, int dayNumber) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final sectionHeight = boxSize * 0.3;
        final fontSize = sectionHeight * 0.6;
        final clampedFontSize = fontSize.clamp(12.0, 32.0);
        
        final bgColor = widget.isDayMode
          ? Colors.white
          : Colors.grey.shade800;
        
        final hasData = dayData != null && (dayData.hasFoodIntake || dayData.hasFitness);
        final borderColor = hasData ? Colors.blue : Colors.grey.shade300;
        final textColor = widget.isDayMode ? Colors.black87 : Colors.white;
        
        return Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: hasData ? 2 : 1),
            borderRadius: BorderRadius.circular(boxSize * 0.18),
            boxShadow: hasData ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day number
              SizedBox(
                height: sectionHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: clampedFontSize,
                      ),
                    ),
                  ),
                ),
              ),
              // Checkmarks section
              if (dayData != null && (dayData.hasFoodIntake || dayData.hasFitness)) ...[
                SizedBox(
                  height: sectionHeight * 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (dayData.hasFoodIntake)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: clampedFontSize * 0.6,
                              color: Colors.green,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '🍽️',
                              style: TextStyle(fontSize: clampedFontSize * 0.5),
                            ),
                          ],
                        ),
                      if (dayData.hasFitness)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: clampedFontSize * 0.6,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '💪',
                              style: TextStyle(fontSize: clampedFontSize * 0.5),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showDayDetail(DateTime date, String dateStr) {
    // Get all entries for this date
    final dayEntries = _allEntries.where((entry) {
      final entryDateStr = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      return entryDateStr == dateStr;
    }).toList();
    
    // Get all activities for this date
    final dayActivities = _allActivities.where((activity) {
      final activityDateStr = DateFormat('yyyy-MM-dd').format(activity.timestamp);
      return activityDateStr == dateStr;
    }).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        final bgColor = widget.isDayMode
            ? Colors.white
            : Colors.grey.shade800;
        final fgColor = widget.isDayMode ? Colors.black87 : Colors.white;
        
        return AlertDialog(
          backgroundColor: bgColor,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: TextStyle(color: fgColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily Summary',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Food Intake Section
              if (dayEntries.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Food Intake',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dayEntries.map((entry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: widget.isDayMode
                      ? Colors.green.shade50
                      : Colors.green.shade900.withOpacity(0.3),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.fastfood, color: Colors.green, size: 16),
                    ),
                    title: Text(entry.food, style: TextStyle(color: fgColor)),
                    subtitle: Text(entry.period, style: TextStyle(color: fgColor.withOpacity(0.7))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.calories} kcal',
                          style: TextStyle(fontWeight: FontWeight.bold, color: fgColor),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deleteEntry(entry.id),
                          child: Icon(Icons.close, color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDayMode ? Colors.green.shade50 : Colors.green.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Calories',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _contrastColor(widget.isDayMode ? Colors.green.shade50 : Colors.green.shade900.withOpacity(0.3))),
                      ),
                      Text(
                        '${dayEntries.fold(0, (sum, e) => sum + e.calories)} kcal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDayMode ? Colors.green : Colors.green.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Fitness Section
              if (dayActivities.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fitness Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dayActivities.map((activity) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: widget.isDayMode
                      ? Colors.orange.shade50
                      : Colors.orange.shade900.withOpacity(0.3),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(Icons.directions_run, color: Colors.orange, size: 16),
                    ),
                    title: Text(activity.name, style: TextStyle(color: fgColor)),
                    subtitle: Text('${activity.duration} minutes', style: TextStyle(color: fgColor.withOpacity(0.7))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${activity.caloriesBurned?.toStringAsFixed(0) ?? '0'} kcal',
                          style: TextStyle(fontWeight: FontWeight.bold, color: fgColor),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deleteActivity(activity.id),
                          child: Icon(Icons.close, color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDayMode ? Colors.orange.shade50 : Colors.orange.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Duration', style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.orange.shade50 : Colors.orange.shade900.withOpacity(0.3)))),
                          Text(
                            '${dayActivities.fold(0, (sum, a) => sum + a.duration)} min',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _contrastColor(widget.isDayMode ? Colors.orange.shade50 : Colors.orange.shade900.withOpacity(0.3))),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calories Burned', style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.orange.shade50 : Colors.orange.shade900.withOpacity(0.3)))),
                          Text(
                            '${dayActivities.fold(0.0, (sum, a) => sum + (a.caloriesBurned ?? 0)).toStringAsFixed(0)} kcal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isDayMode ? Colors.orange : Colors.orange.shade200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              if (dayEntries.isEmpty && dayActivities.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No data for this day',
                      style: TextStyle(color: fgColor.withOpacity(0.6)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDayTile(DaySummary summary) {
    final statusColor = _getStatusColor(summary.totalCalories);
    final statusText = _getStatusText(summary.totalCalories);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: statusColor,
          ),
        ),
        title: Text(
          DateFormat('EEE, MMM d').parse(summary.date).toString().split(' ')[0],
        ),
        subtitle: Text(summary.date),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary.totalCalories} kcal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              statusText,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAverageCalories(Map<String, DayData> days) {
    final trackedDays = days.values.where((d) => d.summary != null).toList();
    if (trackedDays.isEmpty) return 0;
    
    final total = trackedDays.fold<int>(
      0,
      (sum, dayData) => sum + (dayData.summary?.totalCalories ?? 0),
    );
    
    return (total / trackedDays.length).round();
  }

  Future<void> _deleteEntry(String entryId) async {
    await _storageService.removeEntry(entryId);
    _refreshHistory();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food entry deleted')),
    );
  }

  Future<void> _deleteActivity(String activityId) async {
    await _storageService.removeActivity(activityId);
    _refreshHistory();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity deleted')),
    );
  }
}
