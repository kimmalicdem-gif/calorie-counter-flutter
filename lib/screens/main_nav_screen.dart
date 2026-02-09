import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import '../models/food_database.dart';
import 'food_editor_screen.dart';
import 'personalize_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({Key? key}) : super(key: key);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  late final FoodDatabase _foodDatabase = FoodDatabase();
  late final List<Widget> _screens = [
    HomeScreen(foodDatabase: _foodDatabase),
    const HistoryScreen(),
    FoodEditorScreen(foodDatabase: _foodDatabase),
    PersonalizeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Personalize',
          ),
        ],
      ),
    );
  }
}
