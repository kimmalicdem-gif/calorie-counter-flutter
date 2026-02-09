import 'package:intl/intl.dart';

class CalorieEntry {
  final String id;
  final String period; // AM, PM, Night
  final String food;
  final int calories;
  final DateTime timestamp;

  CalorieEntry({
    required this.id,
    required this.period,
    required this.food,
    required this.calories,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'food': food,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalorieEntry.fromJson(Map<String, dynamic> json) {
    return CalorieEntry(
      id: json['id'] as String,
      period: json['period'] as String,
      food: json['food'] as String,
      calories: json['calories'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class DaySummary {
  final String date;
  final int totalCalories;
  final double? weight;

  DaySummary({
    required this.date,
    required this.totalCalories,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'weight': weight,
    };
  }

  factory DaySummary.fromJson(Map<String, dynamic> json) {
    return DaySummary(
      date: json['date'] as String,
      totalCalories: json['totalCalories'] as int,
      weight: json['weight'] as double?,
    );
  }
}
