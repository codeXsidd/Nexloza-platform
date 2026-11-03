# Testing

> NexIoza testing strategy and instructions.

## Flutter Tests

```bash
cd app
flutter test              # Run all tests
flutter test --coverage   # With coverage
flutter analyze           # Static analysis
dart format --set-exit-if-changed lib/ test/  # Formatting check
```

### Test Suite (Phase 2)

**58 tests** across 12 test files:

- **Model tests** (`test/core/models/models_test.dart`): Profile, Organization, OrganizationMember, Project, ProjectMember, ProjectCategory, Invitation — fromJson, toJson, copyWith, role helpers, expiry detection
- **Export service tests** (`test/core/services/export_service_test.dart`): Export/import round-trip, invalid JSON handling
- **Widget tests**: HomeScreen, SettingsScreen, ProjectsScreen, OrganizationsScreen, NotificationsScreen — rendering, empty states
- **Shared widget tests**: NexiozaButton, NexiozaEmptyState, NexiozaStatCard
- **App tests**: Router, theme, app instantiation

### Running Tests

```bash
cd app
flutter test                     # All tests
flutter test test/core/          # Core tests only
flutter test test/features/      # Feature tests only
```

## Backend Tests (pgTAP)

Database security tests in `backend/supabase/tests/`:

```bash
# Requires Supabase CLI + Docker
supabase db test
```

### Test Coverage
- Schema existence (public, private)
- Table existence (8 tables)
- RLS policy verification per table
- Version column existence (optimistic concurrency)
- Private helper function existence (5 functions)
- Public API wrapper existence (4 key wrappers)

## Build Verification

```bash
cd app
flutter build web                # Web build
flutter build windows --debug    # Windows build
flutter build apk --debug        # Android build (requires network for Gradle)
```

## Security Tests

Security is enforced at the database level:
- All RLS policies block direct mutations
- All writes go through RPC (SECURITY INVOKER → SECURITY DEFINER)
- pgTAP tests verify policy names and function signatures
- Static analysis (`flutter analyze`) catches code-level issues

## Integration Tests

<!-- TODO: End-to-end test instructions — Phase 7 -->

## Device Tests

<!-- TODO: Firmware and simulator tests — Phase 7 -->
