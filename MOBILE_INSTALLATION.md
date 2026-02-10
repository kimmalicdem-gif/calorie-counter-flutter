Mobile Installation Guide

This document explains how to build and install the Flutter "Calorie Counter" app on Android and iOS devices.

**Prerequisites**
- Flutter SDK installed and in PATH (see https://flutter.dev/docs/get-started/install)
- Dart (bundled with Flutter)
- Android Studio (for Android SDK and emulator) and Android SDK platform-tools
- For iOS builds: a macOS machine with Xcode and Xcode command line tools
- USB cable for device testing or a configured emulator/simulator

**Notes**
- You can build and run the app in debug directly from your IDE (`flutter run`) while a device/emulator is attached.
- Building iOS apps requires macOS and proper code signing (Apple Developer account) to install on physical devices.


Android (Debug / Quick test)
1. Enable Developer options and USB debugging on your Android device.
2. Connect the device via USB or start an Android emulator.
3. From project root, run:

```bash
flutter devices       # confirm device is visible
flutter run           # builds and installs debug build to device/emulator
```

Android (Release APK)
1. To create a release APK:

```bash
flutter build apk --release
```

2. The unsigned release APK will be at: `build/app/outputs/flutter-apk/app-release.apk`.
3. To install via ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Android (App Bundle for Play Store)
1. Build an Android App Bundle (recommended for Play Store):

```bash
flutter build appbundle --release
```

2. The AAB will be at: `build/app/outputs/bundle/release/app-release.aab`.
3. Upload the `.aab` to Google Play Console.

Signing for Release
- For publishing, configure a signing key (`key.jks`) and update `android/app/build.gradle` or `key.properties` accordingly.
- See Flutter docs: https://flutter.dev/docs/deployment/android


iOS (Debug / Simulator)
- On macOS, open a terminal in project root and run:

```bash
flutter devices
flutter run             # uses the attached device or simulator
```

iOS (Release / App Store)
- Building and installing to a real iOS device or App Store requires a valid Apple Developer account and provisioning profiles.
- Use Xcode to manage signing and to archive the app for distribution.
- See Flutter docs: https://flutter.dev/docs/deployment/ios


Troubleshooting & Tips
- If `flutter doctor` reports missing dependencies, follow the provided steps to resolve them.
- If texts or UI appear unreadable on Night Mode, try rebuilding (`flutter clean` then `flutter run`) after changing theme settings.
- For sideloading on some devices you may need to allow unknown sources or accept installation prompts.


Commands summary

```bash
# show devices
flutter devices

# run debug build to attached device/emulator
flutter run

# build release APK
flutter build apk --release

# install APK via adb
adb install -r build/app/outputs/flutter-apk/app-release.apk

# build Android App Bundle
flutter build appbundle --release

# build iOS (macOS only)
flutter build ios --release
```

If you want, I can commit these changes and push them to the remote now, and also commit the UI fix already made. Do you want me to proceed with committing and pushing both changes?