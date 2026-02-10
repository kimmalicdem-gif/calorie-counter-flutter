import 'package:flutter/material.dart';
import '../../models/food_database.dart';

class FoodSelector extends StatefulWidget {
  final FoodDatabase foodDatabase;
  final String? selectedCategory;
  final Food? selectedFood;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Food> onFoodChanged;

  final bool isDayMode;
  const FoodSelector({
    Key? key,
    required this.foodDatabase,
    required this.selectedCategory,
    required this.selectedFood,
    required this.onCategoryChanged,
    required this.onFoodChanged,
    required this.isDayMode,
  }) : super(key: key);

  @override
  State<FoodSelector> createState() => _FoodSelectorState();
}

class _FoodSelectorState extends State<FoodSelector> {
  late List<String> _categories;
  late List<Food> _foods;

  @override
  void initState() {
    super.initState();
    _categories = widget.foodDatabase.getCategories();
    _foods = widget.selectedCategory != null
        ? widget.foodDatabase.getFoodsForCategory(widget.selectedCategory!)
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    final selectorBg = widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade900;
    final expandedBg = widget.isDayMode ? Colors.grey.shade200 : Colors.grey.shade800;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Food',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fgColor),
        ),
        const SizedBox(height: 12),

        // Category Dropdown
        Container(
          color: selectorBg,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: expandedBg,
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Row(
                children: [
                  const Icon(Icons.folder_open, color: Color(0xFF667EEA)),
                  const SizedBox(width: 8),
                  Text('Select Category...', style: TextStyle(color: fgColor)),
                ],
              ),
              value: widget.selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(Icons.folder, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(category, style: TextStyle(color: fgColor)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (category) {
                if (category != null) {
                  widget.onCategoryChanged(category);
                  setState(() {
                    _foods = widget.foodDatabase.getFoodsForCategory(category);
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Food Dropdown
        Container(
          color: selectorBg,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: expandedBg,
            ),
            child: DropdownButton<Food>(
              isExpanded: true,
              hint: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Color(0xFF667EEA)),
                  const SizedBox(width: 8),
                  Text('Choose Food...', style: TextStyle(color: fgColor)),
                ],
              ),
              value: widget.selectedFood,
              items: _foods.map((food) {
                return DropdownMenuItem(
                  value: food,
                  child: Row(
                    children: [
                      Icon(Icons.fastfood, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text('${food.name} (${food.calories} kcal)', style: TextStyle(color: fgColor)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: widget.selectedCategory != null ? (food) {
                if (food != null) {
                  widget.onFoodChanged(food);
                }
              } : null,
            ),
          ),
        ),

        // Display selected food calories
        if (widget.selectedFood != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.selectedFood!.name, style: TextStyle(color: fgColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.selectedFood!.calories} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
