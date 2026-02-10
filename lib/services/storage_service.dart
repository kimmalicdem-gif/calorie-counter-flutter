import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/calorie_entry.dart';
import '../models/user_profile.dart';
import '../models/activity.dart';

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
  static const String _profileKey = 'userProfile';
  static const String _activitiesKey = 'activities';

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
    try {
      final jsonList = _prefs.getStringList(_entriesKey) ?? [];
      return jsonList
          .map((json) {
            try {
              return CalorieEntry.fromJson(jsonDecode(json));
            } catch (e) {
              print('Error parsing entry: $e');
              return null;
            }
          })
          .whereType<CalorieEntry>()
          .toList();
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }

  Future<void> saveDaySummary(int totalCalories, {double? weight}) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final history = getHistory();
    history.add(DaySummary(date: today, totalCalories: totalCalories, weight: weight));
    final jsonList = history.map((h) => jsonEncode(h.toJson())).toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }

  List<DaySummary> getHistory() {
    try {
      final jsonList = _prefs.getStringList(_historyKey) ?? [];
      return jsonList
          .map((json) {
            try {
              return DaySummary.fromJson(jsonDecode(json));
            } catch (e) {
              print('Error parsing history: $e');
              return null;
            }
          })
          .whereType<DaySummary>()
          .toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  Future<void> clearEntries() async {
    await _prefs.setStringList(_entriesKey, []);
  }

  // Profile methods
  Future<void> saveProfile(UserProfile profile) async {
    final json = jsonEncode(profile.toJson());
    await _prefs.setString(_profileKey, json);
  }

  UserProfile? getProfile() {
    try {
      final json = _prefs.getString(_profileKey);
      if (json == null) return null;
      return UserProfile.fromJson(jsonDecode(json));
    } catch (e) {
      print('Error parsing profile: $e');
      return null;
    }
  }

  // Activity methods
  Future<void> addActivity(Activity activity) async {
    final activities = getActivities();
    activities.add(activity);
    final jsonList = activities.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_activitiesKey, jsonList);
  }

  Future<void> removeActivity(String id) async {
    final activities = getActivities();
    activities.removeWhere((a) => a.id == id);
    final jsonList = activities.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_activitiesKey, jsonList);
  }

  List<Activity> getActivities() {
    try {
      final jsonList = _prefs.getStringList(_activitiesKey) ?? [];
      return jsonList
          .map((json) {
            try {
              return Activity.fromJson(jsonDecode(json));
            } catch (e) {
              print('Error parsing activity: $e');
              return null;
            }
          })
          .whereType<Activity>()
          .toList();
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

  Future<void> clearActivities() async {
    await _prefs.setStringList(_activitiesKey, []);
  }

  Future<void> clearCalendarHistory() async {
    await _prefs.setStringList(_historyKey, []);
    await _prefs.setStringList(_entriesKey, []);
    await _prefs.setStringList(_activitiesKey, []);
  }
}
