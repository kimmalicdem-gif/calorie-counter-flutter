import 'package:shared_preferences/shared_preferences.dart';

class CalorieLimitService {
  static const String _minKey = 'minCalorieLimit';
  static const String _maxKey = 'maxCalorieLimit';
  static const int defaultMin = 1900;
  static const int defaultMax = 2100;

  static Future<int> getMin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minKey) ?? defaultMin;
  }

  static Future<int> getMax() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxKey) ?? defaultMax;
  }

  static Future<void> setMin(int min) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minKey, min);
  }

  static Future<void> setMax(int max) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxKey, max);
  }
}
