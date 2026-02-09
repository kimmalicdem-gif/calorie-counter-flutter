import 'package:flutter/material.dart';
import 'screens/main_nav_screen.dart';

void main() {
  runApp(const CalorieCounterApp());
}

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Counter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavScreen(),
    );
  }
}
