# Installation Guide

> Complete installation instructions for NexIoza.

## Requirements

- Flutter 3.47+ (stable)
- Android SDK 34+
- Docker (for local backend services)
- Node.js 18+ (for simulator and tooling)

## Clone Repository

```bash
git clone https://github.com/your-org/nexioza-platform.git
cd nexioza-platform
```

## Flutter Setup

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

## Backend Setup

<!-- TODO: Supabase local dev instructions — Phase 3 -->

## MQTT Setup

<!-- TODO: Mosquitto Docker setup — Phase 3 -->

## First Run

```bash
cd app
flutter run
```
