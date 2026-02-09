import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/calorie_entry.dart';

class ExportService {
  static Future<String> generateCSV(List<CalorieEntry> entries) async {
    List<List<dynamic>> rows = [
      ['Date', 'Period', 'Food', 'Calories'],
    ];

    for (final entry in entries) {
      rows.add([
        entry.timestamp.toIso8601String().split('T')[0],
        entry.period,
        entry.food,
        entry.calories,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  static Future<String> saveCSV(String csv, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csv);
    return file.path;
  }
}
