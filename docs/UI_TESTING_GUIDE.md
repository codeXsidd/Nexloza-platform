# NexIoza UI Testing Guide

## Test File Location

Phase 10 tests: `app/test/phase10_test.dart`

## Test Categories

### Design System Tests

Verify color tokens, spacing values, and typography definitions are correct.

```bash
flutter test test/phase10_test.dart --name "Design System"
```

### Responsive Breakpoint Tests

Test `AppBreakpoints.fromWidth()` at boundary values:
- 599px → compactMobile
- 600px → mobile
- 899px → mobile
- 900px → tablet
- 1199px → tablet
- 1200px → desktop
- 1439px → desktop
- 1440px → wideDesktop

### Component Render Tests

Each design system component is tested for basic rendering:
- `NexStatCard` — Shows label and value
- `NexDeviceCard` — Shows device name and online status
- `NexAlarmCard` — Shows title and severity badge
- `NexIntegrationCard` — Shows integration name and status
- `NexSectionHeader` — Shows title and action
- `NexErrorPanel` — Shows error message and retry button
- `NexLoadingSkeleton` — Renders with correct dimensions

### Navigation Tests

Verify route names exist and the 5-tab structure is correct.

### Widget Registry Preservation

Verify 47 widget types are still registered after Phase 10 changes.

## Running Tests

```bash
# Full suite
cd app && flutter test

# Phase 10 only
flutter test test/phase10_test.dart

# With verbose output
flutter test --reporter expanded

# Specific group
flutter test --name "Responsive"
```

## Responsive Testing

Use Chrome DevTools device toolbar to test at representative viewports:

| Viewport | Expected Layout |
|---|---|
| 360 × 800 | Bottom nav, single column |
| 768 × 1024 | Navigation rail, 3 columns |
| 1440 × 900 | Full sidebar, 4 columns |
| 1920 × 1080 | Full sidebar (wide), 4 columns |

## Theme Testing

Toggle between light and dark themes in Settings. Verify:
- All text remains readable
- Charts use appropriate colors
- Cards have correct backgrounds
- Navigation indicators are visible
- Status colors are distinguishable
