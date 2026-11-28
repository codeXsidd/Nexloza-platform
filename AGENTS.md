# Nexloza development instructions

- Extend the existing application. Read [the development handoff](docs/DEVELOPMENT_HANDOFF.md) and the relevant implementation and tests before acting on historical reports.
- Use the existing checkout in Codex Cloud. Work on a separate development branch based on `main` and open a pull request for review. Merge only when explicitly authorized.
- Run Flutter commands from `app/`. The manifest requires Dart `^3.13.4` and the lockfile requires Flutter `>=3.47.0`. Flutter 3.47.5 supplies Dart 3.13.4. Preserve `pubspec.lock` during setup with `flutter pub get --enforce-lockfile`. Treat SDK and major dependency changes as separate, deliberate changes.
- Run `dart format --output=none --set-exit-if-changed .`, `flutter analyze --no-fatal-infos`, and `flutter test` for the app baseline. Use focused tests during development and capture the final suite totals from the runner. Record skipped or blocked checks separately.
- Keep feature code in the existing feature-first Riverpod and GoRouter structure. Reuse the data repositories, MQTT topic constants, and simulator rather than duplicating their responsibilities.
- Use a disposable development Supabase instance and MQTT broker for integration checks. Apply migrations only to a verified development target. Keep service-role keys, broker credentials, tokens, and production data out of the repository and logs. Client builds accept only the public Supabase key.
- Verify device, tenant, and project scope in changes involving RLS, offline replay, or MQTT. Check locally queued data and reconnect behavior before changing replay semantics.
- An emulator attached to a developer's Windows machine is separate from Codex Cloud. Report actual device availability and use the handoff commands for local Android verification.
