import '../services/calorie_limit_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calorie_entry.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  late DateTime _selectedMonth;
  late List<DaySummary> _history;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _history = [];
  }

  @override
  // Removed duplicate didChangeDependencies

  void _refreshHistory() {
    setState(() {
      _history = _storageService.getHistory();
    });
  }

  Map<String, DaySummary?> _getDaysInMonth() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    Map<String, DaySummary?> days = {};
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    int todayTotal = 0;
    if (_selectedMonth.year == today.year && _selectedMonth.month == today.month) {
      // Get today's total from current entries
      final storage = StorageService();
      todayTotal = storage.getEntries().fold(0, (sum, entry) => sum + entry.calories);
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
      days[dateStr] = summary.totalCalories > 0 ? summary : null;
    }
    return days;
  }

  String _getStatusText(int calories) {
    if (calories < 1900) return 'Low';
    if (calories <= 2100) return 'On Target';
    return 'Over';
  }
  int _maxTarget = 2100;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Navigation
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
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
                      days.values.where((d) => d != null).length.toString(),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Weekday headers
                      GridView.count(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            .map((day) => Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar days
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 42,
                        itemBuilder: (context, index) {
                          final dayNumber = index - (firstDayWeekday - 1) + 1;
                          
                          if (dayNumber <= 0 || dayNumber > daysInMonth) {
                            return const SizedBox();
                          }

                          final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final summary = days[dateStr];

                          return _buildDayCard(summary, dayNumber);
                        },
                      ),
                    ],
                  ),
                ),
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
    );
  }

  Widget _buildDayCard(DaySummary? summary, int dayNumber) {
    if (summary == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            dayNumber.toString(),
            style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(summary.totalCalories);
    final statusBgColor = _getStatusBgColor(summary.totalCalories);
    final textColor = statusBgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: statusBgColor,
        border: Border.all(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayNumber.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalCalories}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
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

  int _calculateAverageCalories(Map<String, DaySummary?> days) {
    final trackedDays = days.values.where((d) => d != null).toList();
    if (trackedDays.isEmpty) return 0;
    
    final total = trackedDays.fold<int>(
      0,
      (sum, day) => sum + (day?.totalCalories ?? 0),
    );
    
    return (total / trackedDays.length).round();
  }
}
