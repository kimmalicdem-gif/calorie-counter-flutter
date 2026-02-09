import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/calorie_entry.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  late SharedPreferences _prefs;
  static const String _entriesKey = 'entries';
  static const String _historyKey = 'history';
  static const String _dateKey = 'date';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndResetDay();
  }

  Future<void> _checkAndResetDay() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = _prefs.getString(_dateKey);

    if (lastDate != today) {
      final entries = getEntries();
      if (entries.isNotEmpty) {
        final total = entries.fold<int>(0, (sum, entry) => sum + entry.calories);
        await saveDaySummary(total);
      }
      await _prefs.setString(_dateKey, today);
      await _prefs.setStringList(_entriesKey, []);
    }
  }

  Future<void> addEntry(CalorieEntry entry) async {
    final entries = getEntries();
    entries.add(entry);
    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_entriesKey, jsonList);
  }

  Future<void> removeEntry(String id) async {
    final entries = getEntries();
    entries.removeWhere((e) => e.id == id);
    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_entriesKey, jsonList);
  }

  Future<void> updateEntry(CalorieEntry entry) async {
    final entries = getEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entries[index] = entry;
      final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
      await _prefs.setStringList(_entriesKey, jsonList);
    }
  }

  List<CalorieEntry> getEntries() {
    final jsonList = _prefs.getStringList(_entriesKey) ?? [];
    return jsonList
        .map((json) => CalorieEntry.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveDaySummary(int totalCalories, {double? weight}) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final history = getHistory();
    history.add(DaySummary(date: today, totalCalories: totalCalories, weight: weight));
    final jsonList = history.map((h) => jsonEncode(h.toJson())).toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }

  List<DaySummary> getHistory() {
    final jsonList = _prefs.getStringList(_historyKey) ?? [];
    return jsonList
        .map((json) => DaySummary.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> clearEntries() async {
    await _prefs.setStringList(_entriesKey, []);
  }
}
