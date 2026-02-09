
import 'dart:convert';
import 'package:flutter/services.dart';

class FoodDatabase {
  static final FoodDatabase _instance = FoodDatabase._internal();

  factory FoodDatabase() {
    return _instance;
  }

  FoodDatabase._internal();

  Map<String, List<Food>>? categories;

  bool get isLoaded => categories != null;

  void addFood(String category, Food food) {
    if (categories == null) return;
    if (!categories!.containsKey(category)) {
      categories![category] = [];
    }
    categories![category]!.add(food);
  }

  Future<void> loadFoods() async {
    final jsonString = await rootBundle.loadString('assets/foods.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    
    categories = {};
    jsonData.forEach((category, foods) {
      categories![category] = (foods as List)
          .map((food) => Food.fromJson(food as Map<String, dynamic>))
          .toList();
    });
  }


  List<String> getCategories() => categories?.keys.toList() ?? [];

  List<Food> getFoodsForCategory(String category) => categories?[category] ?? [];

  Food? searchFood(String query) {
    final lowerQuery = query.toLowerCase();
    for (final foods in categories?.values ?? const Iterable<List<Food>>.empty()) {
      for (final food in foods) {
        if (food.name.toLowerCase().contains(lowerQuery)) {
          return food;
        }
      }
    }
    return null;
  }
}

class Food {
  final String name;
  final int calories;

  Food({required this.name, required this.calories});

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] as String,
      calories: json['calories'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
    };
  }
}
