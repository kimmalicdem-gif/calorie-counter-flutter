import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';

class PersonalizeScreen extends StatefulWidget {
  final bool isDayMode;
  final ValueChanged<bool> onModeChanged;
  const PersonalizeScreen({Key? key, required this.isDayMode, required this.onModeChanged}) : super(key: key);

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  final _storageService = StorageService();

  Color _contrastColor(Color c) => c.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  
  // Profile fields
  final _nicknameController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _goalWeightController = TextEditingController();
  
  // Calorie limit fields
  int _minCal = 1900;
  int _maxCal = 2100;
  bool _loading = true;

  static const String _minKey = 'minCalorieLimit';
  static const String _maxKey = 'maxCalorieLimit';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _storageService.init();
    final prefs = await SharedPreferences.getInstance();
    final profile = _storageService.getProfile();
    
    setState(() {
      // Load profile
      _nicknameController.text = profile?.nickname ?? '';
      _currentWeightController.text = profile?.weight.toString() ?? '';
      _goalWeightController.text = profile?.targetWeight?.toString() ?? '';
      
      // Load calorie limits
      _minCal = prefs.getInt(_minKey) ?? 1900;
      _maxCal = prefs.getInt(_maxKey) ?? 2100;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final currentWeight = double.tryParse(_currentWeightController.text.trim());
    final goalWeight = double.tryParse(_goalWeightController.text.trim());

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
      return;
    }

    if (currentWeight == null || currentWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid current weight')),
      );
      return;
    }

    if (goalWeight != null && goalWeight >= currentWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal weight must be less than current weight')),
      );
      return;
    }

    final profile = UserProfile(
      nickname: nickname,
      weight: currentWeight,
      targetWeight: goalWeight,
    );

    await _storageService.saveProfile(profile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    }
  }

  Future<void> _saveLimits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minKey, _minCal);
    await prefs.setInt(_maxKey, _maxCal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calorie limits saved!')),
      );
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('This will delete all your food entries, activities, and calendar history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearCalendarHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDayMode ? Colors.white : Colors.grey.shade900;
    final fgColor = _contrastColor(bgColor);
    // Card and field fill colors
    final cardColor = widget.isDayMode ? Colors.white : Colors.grey.shade800;
    final cardTextColor = _contrastColor(cardColor);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Profile Section
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Nickname Field
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: 'Nickname (Username)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800,
                        labelStyle: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800).withOpacity(0.7)),
                        prefixIcon: Icon(Icons.person, color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                      ),
                      style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Current Weight Field
                    TextFormField(
                      controller: _currentWeightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Current Weight (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800,
                        labelStyle: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800).withOpacity(0.7)),
                        prefixIcon: Icon(Icons.monitor_weight, color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                      ),
                      style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Goal Weight Field
                    TextFormField(
                      controller: _goalWeightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Goal Weight (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800,
                        labelStyle: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800).withOpacity(0.7)),
                        prefixIcon: Icon(Icons.flag, color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                        hintText: 'For weight loss projection',
                        hintStyle: TextStyle(
                          color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800).withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade100 : Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 20),
                    
                    // Save Profile Button
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Personalize Settings Card
                    Card(
                      elevation: 4,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: cardTextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Day/Night Mode Toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      widget.isDayMode ? Icons.light_mode : Icons.dark_mode,
                                      color: cardTextColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      widget.isDayMode ? "Day Mode" : "Night Mode",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: cardTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: widget.isDayMode,
                                  onChanged: widget.onModeChanged,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            
                            // Calorie Intake Limit
                            Text(
                              'Calorie Intake Limit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: cardTextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _minCal.toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Min',
                                      labelStyle: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800).withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800)),
                                    onChanged: (v) => setState(() => _minCal = int.tryParse(v) ?? _minCal),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _maxCal.toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Max',
                                      labelStyle: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800).withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800,
                                    ),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: _contrastColor(widget.isDayMode ? Colors.grey.shade50 : Colors.grey.shade800)),
                                    onChanged: (v) => setState(() => _maxCal = int.tryParse(v) ?? _maxCal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _saveLimits,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Limits'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const Divider(height: 32),
                            
                            // Clear Calendar Button
                            ElevatedButton.icon(
                              onPressed: _clearHistory,
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Clear Calendar (History)'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
