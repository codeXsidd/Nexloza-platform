# Android Setup Guide

## Prerequisites

- **Flutter SDK** 3.24+ installed and on PATH
- **Android Studio** with Android SDK (API 34 recommended)
- **Java 17** (bundled with Android Studio)
- Physical device or emulator running Android 7.0+ (API 24+)

## First-Time Setup

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/codeXsidd/nexloza.git
cd nexloza/app
flutter pub get
```

### 2. Environment Configuration

Create `app/.env` with your Supabase credentials:

```env
SUPABASE_URL=https://gwxaansxqdxkofrplfqx.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
MQTT_HOST=your_broker_host
MQTT_PORT=1883
```

**Security**: Never commit `.env` to version control. It is already in `.gitignore`.

### 3. Android Emulator

```bash
flutter emulators --launch <emulator_id>
# or
flutter devices   # list connected devices
```

### 4. Run the App

```bash
cd nexloza/app
flutter run
```

For release builds:
```bash
flutter build apk --release
```

The APK will be at `app/build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```
app/
  lib/
    config/          # Environment config, constants
    core/            # Services (MQTT, logger), utilities
    features/        # Feature modules (clean architecture)
      authentication/
      projects/
      devices/
      automations/
      ai_assistant/
      ...
    routing/         # GoRouter configuration
    shared/          # Common widgets, theme
    theme/           # Material 3 theme, colors, spacing
  test/              # Unit and widget tests
```

## Minimum SDK Versions

Configured in `app/android/app/build.gradle`:
- `minSdkVersion`: 24 (Android 7.0)
- `targetSdkVersion`: 34 (Android 14)
- `compileSdkVersion`: 34

## Permissions

The app requires these Android permissions (declared in `AndroidManifest.xml`):
- `INTERNET` — Supabase API and MQTT broker communication
- `ACCESS_NETWORK_STATE` — network connectivity checks

## MQTT Broker Connection

For local development with NanoMQ:

```bash
docker run -d --name nanomq -p 1883:1883 -p 8083:8083 emqx/nanomq:0.22.6-slim
```

Set `MQTT_HOST=10.0.2.2` (Android emulator's host loopback) or your machine's LAN IP for physical devices.

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `MQTT connection refused` | Ensure broker is running and port 1883 is accessible |
| `10.0.2.2 not working` | Only works in Android emulator; use LAN IP for physical devices |
| `Gradle build fails` | Run `flutter clean` then `flutter pub get` |
| `SDK version mismatch` | Run `flutter doctor` and follow recommendations |
| White screen on launch | Check `.env` file exists and has valid Supabase URL |

## Running Tests

```bash
cd nexloza/app
flutter test              # all tests
flutter test --coverage   # with coverage report
flutter analyze           # static analysis
```
