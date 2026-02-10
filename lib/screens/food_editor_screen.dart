import 'package:flutter/material.dart';
import '../models/food_database.dart';

class FoodEditorScreen extends StatefulWidget {
  final FoodDatabase? foodDatabase;
  final bool isDayMode;
  const FoodEditorScreen({Key? key, this.foodDatabase, required this.isDayMode}) : super(key: key);

  @override
  State<FoodEditorScreen> createState() => _FoodEditorScreenState();
}

class _FoodEditorScreenState extends State<FoodEditorScreen> {
  String? _selectedCategory;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  List<String>? _categories;
  Food? _editingFood;

  @override
  void initState() {
    super.initState();
    // Load categories asynchronously in case foodDatabase is not ready
    Future.delayed(Duration.zero, () async {
      if (widget.foodDatabase == null || !widget.foodDatabase!.isLoaded) {
        await widget.foodDatabase?.loadFoods();
      }
      setState(() {
        _categories = widget.foodDatabase?.getCategories();
      });
    });
  }

  void _addOrEditFood() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    final category = _selectedCategory;
    if (name.isEmpty || calories == null || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }
    if (_editingFood != null) {
      // Edit existing food
      final foods = widget.foodDatabase?.getFoodsForCategory(category);
      final idx = foods?.indexOf(_editingFood!);
      if (foods != null && idx != null && idx >= 0) {
        foods[idx] = Food(name: name, calories: calories);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated $name in $category!')),
        );
      }
      _editingFood = null;
    } else {
      // Add new food
      widget.foodDatabase?.addFood(category, Food(name: name, calories: calories));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $name to $category!')),
      );
    }
    _nameController.clear();
    _caloriesController.clear();
    setState(() {});
  }

  void _startEdit(Food food) {
    _nameController.text = food.name;
    _caloriesController.text = food.calories.toString();
    setState(() {
      _editingFood = food;
    });
  }

  void _deleteFood(Food food) {
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade800;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text('Delete Food', style: TextStyle(color: fgColor)),
        content: Text('Are you sure you want to delete ${food.name}?', style: TextStyle(color: fgColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: fgColor)),
          ),
          TextButton(
            onPressed: () {
              final foods = widget.foodDatabase?.getFoodsForCategory(_selectedCategory!);
              final idx = foods?.indexOf(food);
              if (foods != null && idx != null && idx >= 0) {
                foods.removeAt(idx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${food.name}!')),
                );
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_categories == null || !(widget.foodDatabase?.isLoaded ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }
    final foods = _selectedCategory == null
        ? <Food>[]
        : widget.foodDatabase?.getFoodsForCategory(_selectedCategory!) ?? [];
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = widget.isDayMode ? Colors.black : Colors.white;
    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_editingFood == null ? 'Add New Food' : 'Edit Food', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fgColor)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: fgColor)),
                value: _selectedCategory,
                items: _categories!.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: fgColor)))).toList(),
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Food Name', labelStyle: TextStyle(color: fgColor)),
                style: TextStyle(color: fgColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(labelText: 'Calories', labelStyle: TextStyle(color: fgColor)),
                keyboardType: TextInputType.number,
                style: TextStyle(color: fgColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addOrEditFood,
                icon: Icon(_editingFood == null ? Icons.add : Icons.save),
                label: Text(_editingFood == null ? 'Add Food' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
              if (_selectedCategory != null) ...[
                Text('Foods in $_selectedCategory', style: TextStyle(fontWeight: FontWeight.bold, color: fgColor)),
                const SizedBox(height: 8),
                ...foods.map((food) => ListTile(
                      title: Text(food.name, style: TextStyle(color: fgColor)),
                      subtitle: Text('${food.calories} kcal', style: TextStyle(color: fgColor.withOpacity(0.7))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: fgColor,
                            onPressed: () => _startEdit(food),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteFood(food),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
