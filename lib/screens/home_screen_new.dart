import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/calorie_entry.dart';
import '../models/activity.dart';
import '../services/calorie_burn_service.dart';
import '../services/calorie_limit_service.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isDayMode;
  final Function(int)? onNavigate;
  const HomeScreen({
    Key? key,
    this.isDayMode = false,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storageService;
  UserProfile? _userProfile;
  List<CalorieEntry> _entries = [];
  List<Activity> _activities = [];
  bool _isLoading = true;

  int _calorieTarget = CalorieLimitService.defaultMax;

  String _selectedTimePeriod = 'week'; // day, week, month

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storageService.init();
    final profile = _storageService.getProfile();
    final entries = _storageService.getEntries();
    final activities = _storageService.getActivities();
    final calorieTarget = await CalorieLimitService.getMax();
    setState(() {
      _userProfile = profile;
      _entries = entries;
      _activities = activities;
      _calorieTarget = calorieTarget;
      _isLoading = false;
    });
  }

  int _getDaysInPeriod(String period) {
    switch (period) {
      case 'day':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      default:
        return 7;
    }
  }

  int _getTotalCalorieIntake() {
    if (_entries.isEmpty) return 0;
    
    final now = DateTime.now();
    final days = _getDaysInPeriod(_selectedTimePeriod);
    final cutoffDate = now.subtract(Duration(days: days));
    
    final filteredEntries = _entries
        .where((e) => e.timestamp.isAfter(cutoffDate))
        .toList();
    
    if (filteredEntries.isEmpty) return 0;
    
    return filteredEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.calories,
    );
  }

  double _getAverageCalorieIntake() {
    final total = _getTotalCalorieIntake();
    if (total == 0) return 0;
    final days = _getDaysInPeriod(_selectedTimePeriod);
    return total / days;
  }

  int _getTotalActivityMinutes() {
    if (_activities.isEmpty) return 0;
    
    final now = DateTime.now();
    final days = _getDaysInPeriod(_selectedTimePeriod);
    final cutoffDate = now.subtract(Duration(days: days));
    
    final filteredActivities = _activities
        .where((a) => a.timestamp.isAfter(cutoffDate))
        .toList();
    
    if (filteredActivities.isEmpty) return 0;
    
    return filteredActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.duration,
    );
  }

  double _getAverageActivityMinutes() {
    final total = _getTotalActivityMinutes();
    if (total == 0) return 0;
    final days = _getDaysInPeriod(_selectedTimePeriod);
    return total / days;
  }

  double _getTotalActivityCaloriesBurned() {
    if (_activities.isEmpty) return 0;

    final now = DateTime.now();
    final days = _getDaysInPeriod(_selectedTimePeriod);
    final cutoffDate = now.subtract(Duration(days: days));

    final filteredActivities = _activities
        .where((a) => a.timestamp.isAfter(cutoffDate))
        .toList();

    if (filteredActivities.isEmpty) return 0;

    final weightKg = _userProfile?.weight ?? 70.0;
    return filteredActivities.fold<double>(
      0,
      (sum, activity) {
        final burned = activity.caloriesBurned ??
            CalorieBurnService.calculateCaloriesBurned(
              activityName: activity.name,
              weightKg: weightKg,
              durationMinutes: activity.duration,
            );
        return sum + burned;
      },
    );
  }

  double _getAverageActivityCaloriesBurned() {
    final total = _getTotalActivityCaloriesBurned();
    if (total == 0) return 0;
    final days = _getDaysInPeriod(_selectedTimePeriod);
    return total / days;
  }

  double _getDailyNetCalorieDeficit() {
    final avgIntake = _getAverageCalorieIntake();
    final avgBurned = _getAverageActivityCaloriesBurned();
    // Deficit = (target - intake) + exercise burned
    // Positive means projected weight loss; negative means projected gain.
    return (_calorieTarget - avgIntake) + avgBurned;
  }

  double? _getDaysToTargetWeight() {
    if (_userProfile == null || _userProfile?.targetWeight == null) return null;
    
    final currentWeight = _userProfile!.weight;
    final targetWeight = _userProfile!.targetWeight!;
    
    if (targetWeight >= currentWeight) return null;
    
    final weightToLose = currentWeight - targetWeight;
    final dailyDeficit = _getDailyNetCalorieDeficit();
    
    if (dailyDeficit <= 0) return null; // No deficit, can't reach target
    
    // 1 kg body fat ≈ 7700 kcal
    final totalCaloriesNeeded = weightToLose * 7700;
    final days = totalCaloriesNeeded / dailyDeficit;
    
    return days;
  }

  List<FlSpot> _getCalorieIntakeChartData() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final dayEntries = _entries.where((e) {
        final entryDateStr = DateFormat('yyyy-MM-dd').format(e.timestamp);
        return entryDateStr == dateStr;
      }).toList();
      
      final totalCal = dayEntries.fold<int>(0, (sum, e) => sum + e.calories);
      spots.add(FlSpot((6 - i).toDouble(), totalCal.toDouble()));
    }
    
    return spots;
  }

  List<FlSpot> _getActivityChartData() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final dayActivities = _activities.where((a) {
        final activityDateStr = DateFormat('yyyy-MM-dd').format(a.timestamp);
        return activityDateStr == dateStr;
      }).toList();
      
      final totalMinutes = dayActivities.fold<int>(0, (sum, a) => sum + a.duration);
      spots.add(FlSpot((6 - i).toDouble(), totalMinutes.toDouble()));
    }
    
    return spots;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;

    if (_isLoading) {
      return Container(
        color: bgColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Profile Not Set',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fgColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile to get started',
                style: TextStyle(color: fgColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(5); // Navigate to Personalize (index 5)
                    }
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 24),
                  label: const Text(
                    'Create Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${_userProfile?.nickname ?? 'User'}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Current Weight: ${_userProfile?.weight.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time Period Selector
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: fgColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Time Period',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['day', 'week', 'month'].map((period) {
                    final isSelected = _selectedTimePeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(
                          period.capitalize(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : fgColor,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimePeriod = period;
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: Colors.blue.shade600,
                        side: BorderSide(
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Weight Loss Projection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weight Loss Projection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.trending_down_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final daysToTarget = _getDaysToTargetWeight();
                        final hasTarget = _userProfile?.targetWeight != null;

                        if (!hasTarget) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No Target Weight Set',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Set your target weight in Profile Settings',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (daysToTarget == null || daysToTarget <= 0) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No Active Deficit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Increase activity or reduce intake to reach target',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final totalIntake = _getTotalCalorieIntake();
                        final avgIntake = _getAverageCalorieIntake();
                        final totalActivityCal = _getTotalActivityCaloriesBurned();
                        final avgActivityCal = _getAverageActivityCaloriesBurned();

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Days to Target',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${daysToTarget.toStringAsFixed(1)} days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Target: ${_userProfile?.targetWeight?.toStringAsFixed(1) ?? "N/A"} kg',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Intake: $totalIntake cal (${avgIntake.toStringAsFixed(1)} Avg. Cal)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Activity: ${totalActivityCal.toStringAsFixed(0)} cal (${avgActivityCal.toStringAsFixed(1)} Avg. Cal)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Average Calorie Intake Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calorie Intake',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.restaurant_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_getTotalCalorieIntake()} cal',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${_getAverageCalorieIntake().toStringAsFixed(1)} Avg. Cal)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getCalorieIntakeChartData(),
                              isCurved: true,
                              color: Colors.white,
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Total Activities Average Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Activities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(Icons.fitness_center_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_getTotalActivityMinutes()} min',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${_getAverageActivityMinutes().toStringAsFixed(1)} Avg. Min)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getActivityChartData(),
                              isCurved: true,
                              color: Colors.white,
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
