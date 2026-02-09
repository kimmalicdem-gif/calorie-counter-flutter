# Calorie Counter - Flutter App

A modern, cross-platform calorie tracking app built with Flutter and Material Design 3.

## Features

✨ **Core Features:**
- Track daily calorie intake with AM/PM/Night periods
- Browse 100+ foods across 15 categories
- Real-time calorie calculation and progress tracking
- Daily summaries with optional weight logging
- CSV export for history tracking
- Local data persistence with `shared_preferences`

🎨 **UI/UX:**
- Material Design 3 components
- Smooth animations and transitions
- Responsive design (mobile, tablet, desktop)
- Dark/light theme support
- Color-coded period indicators

📱 **Cross-Platform:**
- iOS
- Android
- Web
- Windows
- macOS
- Linux

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── home_screen.dart         # Main screen with all features
│   └── widgets/
│       ├── period_selector.dart # AM/PM/Night selector
│       ├── food_selector.dart   # Category & food dropdowns
│       ├── status_card.dart     # Calorie progress display
│       ├── entry_list.dart      # Today's entries list
│       └── bottom_sheet_new_day.dart  # New day dialog
├── models/
│   ├── food_database.dart       # Food data structure & loading
│   └── calorie_entry.dart       # Entry & day summary models
└── services/
    ├── storage_service.dart     # Local storage & persistence
    └── export_service.dart      # CSV export functionality

assets/
└── foods.json                   # 100+ foods across 15 categories
```

## Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+

### Installation

1. **Navigate to project:**
   ```bash
   cd calorie-counter-flutter
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run app:**
   ```bash
   flutter run
   ```

4. **Build for production:**
   - **APK:** `flutter build apk --release`
   - **iOS:** `flutter build ios --release`
   - **Web:** `flutter build web --release`
   - **Windows:** `flutter build windows --release`

## Usage

1. **Select Period:** Choose AM, PM, or Night
2. **Select Food:** 
   - Pick a category from dropdown
   - Select food from that category
   - Calories auto-fill
3. **Add Entry:** Click "Add Entry"
4. **Track Progress:** Watch status card show:
   - Total consumed
   - Remaining calories
   - Color indicator (Green/Yellow/Red)
5. **New Day:** Click "New Day" to save today and reset

## Data Storage

- **Local:** `shared_preferences` stores today's entries
- **History:** Previous days saved as summaries
- **Daily Reset:** Automatic check on app launch

## Architecture Decisions

### State Management
- Simple `StatefulWidget` for local UI state
- `shared_preferences` for persistence
- Single-instance services (food database, storage)

### Data Models
- `Food`: name + calories
- `CalorieEntry`: id, period, food, calories, timestamp
- `DaySummary`: date, total calories, optional weight

### Service Layer
- `FoodDatabase`: Loads and searches foods.json
- `StorageService`: Manages local storage with daily reset logic
- `ExportService`: Generates CSV exports

## Dependencies

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Local data persistence |
| `uuid` | Generate unique entry IDs |
| `csv` | CSV export functionality |
| `intl` | Date formatting |
| `path_provider` | File system access |
| `file_picker` | File selection (future) |

## Future Enhancements

- [ ] Cloud sync (Firebase)
- [ ] Meal photos with ML nutrition detection
- [ ] Social sharing
- [ ] Nutritional breakdown (protein, carbs, fats)
- [ ] Custom food database
- [ ] Reminders & notifications
- [ ] Chart visualization of history

## Known Issues

- Dropdown styling varies slightly per platform
- CSV export requires file permissions on some devices

## License

MIT - Free to use and modify

---

**Web Version:** The original PWA version is available in `/calorie-counter/` folder.
Both versions share the same `foods.json` database.
