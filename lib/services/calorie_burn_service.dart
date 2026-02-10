class CalorieBurnService {
  // MET (Metabolic Equivalent of Task) values for different activities
  static const Map<String, double> _metValues = {
    'Walking (5–5.5 km/h)': 3.5,
    'Running (8 km/h jog)': 8.3,
    'Home Workout (bodyweight, steady)': 4.5,
    'Gym (moderate resistance training)': 4.0,
    'Sports (moderate, recreational)': 6.0,
    'Cycling (16–19 km/h)': 6.8,
  };

  /// Calculates calories burned based on activity, weight, and duration
  /// Formula: Calories = MET × weight(kg) × duration(hours)
  static double calculateCaloriesBurned({
    required String activityName,
    required double weightKg,
    required int durationMinutes,
  }) {
    final met = _metValues[activityName] ?? 3.0; // Default MET value if not found
    final durationHours = durationMinutes / 60.0;
    return met * weightKg * durationHours;
  }

  /// Returns list of available activity names
  static List<String> get availableActivities => _metValues.keys.toList();

  /// Returns MET value for a specific activity
  static double? getMetValue(String activityName) => _metValues[activityName];
}
