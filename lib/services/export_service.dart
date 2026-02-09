import '../models/calorie_entry.dart';

class ExportService {
  static String generateCSV(List<CalorieEntry> entries) {
    StringBuffer csv = StringBuffer();
    csv.writeln('Date,Period,Food,Calories');

    for (final entry in entries) {
      final date = entry.timestamp.toIso8601String().split('T')[0];
      csv.writeln('$date,${entry.period},${entry.food},${entry.calories}');
    }

    return csv.toString();
  }
}

