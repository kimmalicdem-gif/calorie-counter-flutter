import 'package:flutter/material.dart';
import 'home_screen_new.dart';
import 'food_intake_screen.dart';
import 'fitness_screen.dart';
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
  bool _isDayMode = false;
  late final FoodDatabase _foodDatabase = FoodDatabase();

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        isDayMode: _isDayMode,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      FoodIntakeScreen(
        foodDatabase: _foodDatabase,
        isDayMode: _isDayMode,
      ),
      FitnessScreen(isDayMode: _isDayMode),
      HistoryScreen(isDayMode: _isDayMode),
      FoodEditorScreen(foodDatabase: _foodDatabase, isDayMode: _isDayMode),
      PersonalizeScreen(
        isDayMode: _isDayMode,
        onModeChanged: (val) => setState(() => _isDayMode = val),
      ),
    ];

    final appBarTitles = [
      'Home',
      'Food Intake',
      'Fitness',
      'History',
      'Food Editor',
      'Settings',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: _isDayMode ? Colors.white : Colors.grey.shade900,
        foregroundColor: _isDayMode ? Colors.black : Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.favorite_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Wellness App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Striving Healthy Living',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_rounded),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.restaurant_rounded),
              title: const Text('Food Intake'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center_rounded),
              title: const Text('Fitness'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month_rounded),
              title: const Text('History'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded),
              title: const Text('Food Editor'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() => _selectedIndex = 5);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
    );
  }
}
