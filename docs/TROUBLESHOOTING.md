# Troubleshooting

> Common issues and solutions for NexIoza.

## Common Issues

<!-- TODO: FAQ-style troubleshooting — Phase 8 -->

## MQTT Connection

<!-- TODO: MQTT connectivity debugging — Phase 3 -->

## Supabase

<!-- TODO: Backend connection issues — Phase 3 -->

## Flutter Build

### Analysis errors after checkout

```bash
cd app
flutter clean
flutter pub get
flutter analyze
```

### Android build fails

Verify Android SDK and licenses:
```bash
flutter doctor -v
flutter doctor --android-licenses
```

## Device Pairing

<!-- TODO: Device provisioning troubleshooting — Phase 3 -->
