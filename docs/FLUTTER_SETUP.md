# Flutter Development Setup

> Setting up the Flutter development environment for NexIoza.

## Prerequisites

- Flutter 3.47+ on stable channel
- Dart 3.13+
- Android Studio or VS Code with Flutter extension
- Android SDK 34+ with accepted licenses

## Dependencies

Key packages used:

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing |
| `shimmer` | Loading state placeholders |
| `shared_preferences` | Simple local persistence |
| `connectivity_plus` | Network status detection |

## Running

```bash
cd app
flutter pub get
flutter run
```

## Building

```bash
flutter build apk --release       # Release APK
flutter build appbundle --release  # Play Store bundle
flutter build web                  # Web build
```

## Testing

```bash
flutter test                  # All tests
flutter test --coverage       # With coverage report
flutter analyze               # Static analysis
```
