class Activity {
  final String id;
  final String name;
  final int duration; // in minutes
  final DateTime timestamp;
  final double? caloriesBurned;

  Activity({
    required this.id,
    required this.name,
    required this.duration,
    required this.timestamp,
    this.caloriesBurned,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
      if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: json['duration'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      caloriesBurned: json['caloriesBurned'] == null ? null : (json['caloriesBurned'] as num).toDouble(),
    );
  }
}
