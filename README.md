# Shein_Kosova

A Flutter e-commerce application for Shein Kosovo.

## CI/CD Pipeline

This project includes automated CI/CD using GitHub Actions with the following features:

- **Flutter Analyze**: Automatically checks code quality and identifies potential issues
- **Flutter Test**: Runs all unit and widget tests
- **Build APK**: Creates a release Android APK
- **Firebase App Distribution**: Automatically distributes builds to testers

### Workflow Triggers

The CI/CD pipeline runs on:
- Push to `main`, `master`, or `develop` branches
- Pull requests targeting `main`, `master`, or `develop` branches
- Manual workflow dispatch

### Setup

To enable Firebase App Distribution deployment, you need to configure GitHub secrets. See [`.github/FIREBASE_APP_DISTRIBUTION_SETUP.md`](.github/FIREBASE_APP_DISTRIBUTION_SETUP.md) for detailed instructions.

## Development

### Prerequisites

- Flutter SDK (latest stable recommended, must include Dart SDK 3.8.1+)
- Dart SDK (3.8.1 or later)
- Java 17 (for Android builds - configured in workflow and build.gradle.kts)
- Kotlin (project uses Kotlin DSL for Android configuration)
- Android Studio / Xcode (for mobile development)

### Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Android Configuration

The Android project uses:
- **Kotlin DSL** for Gradle build files (`.gradle.kts`)
- **Java 17** for compilation (aligned with CI/CD workflow)
- **Kotlin plugin** for Android development

Build configuration files:
- `android/build.gradle.kts` - Root project configuration
- `android/app/build.gradle.kts` - App module configuration (Kotlin DSL)

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```