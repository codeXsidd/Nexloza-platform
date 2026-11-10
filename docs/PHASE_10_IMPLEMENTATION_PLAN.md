# Phase 10 Implementation Plan

## Objective

Unify NexIoza into a cohesive premium IoT product across Android mobile and web, with a responsive developer console, while preserving all Phase 1–9 functionality.

## Starting State

- **Commit:** `3741e64` (Phase 9)
- **Tests:** 747 passing
- **Analyzer:** 0 issues
- **Widget types:** 47 registered
- **Rule node types:** 39
- **Database migrations:** 20 (00001–00020)

## Implementation Milestones

### Milestone 10.1 — Design System Foundation

1. Update color palette from teal (#00897B) to indigo (#6366F1)
2. Add semantic color tokens (light/dark surfaces, alarm severities, device status)
3. Create responsive breakpoint system (5 levels: compact mobile → wide desktop)
4. Build responsive layout widgets (ResponsiveBuilder, ResponsiveLayout, ResponsiveGrid)
5. Create design system components (stat card, device card, alarm card, integration card, error/offline panels, loading skeletons, section headers)
6. Enhance Material 3 theme with explicit ColorScheme, chip/dialog/popup/snackbar/tab themes

### Milestone 10.2 — Mobile Experience

1. Restructure bottom navigation: Home, Devices, Automation, Analytics, Settings
2. Move Projects and AI Assistant from shell branches to push routes
3. Enhance Home screen with responsive stat grid, device counts
4. Enhance Analytics screen with design system colors and theme-aware charts
5. Enhance Settings screen with Developer, Platform, and notification preference sections

### Milestone 10.3 — Web Developer Console

1. Build collapsible sidebar with 13 navigation items in 3 sections
2. Section labels: Device Management, Intelligence, Platform
3. Wire sidebar to shell branches (5 items) and push routes (8 items)
4. Support collapsed mode (72px) with icon tooltips

### Milestone 10.4 — New Screens

1. Device Templates screen — catalogs ESP32/ESP8266/RPi hardware from existing BoardDefinition data
2. Firmware & OTA screen — honest "coming soon" placeholder
3. Developer Tools screen — API keys, MQTT info, device studio, integrations

### Milestone 10.5 — Quality & Documentation

1. Fix all dart formatting issues (57 pre-existing files)
2. Write 80+ Phase 10 tests covering design system, responsive, components, navigation
3. Run full test suite, analyzer, Android build, web build
4. Write documentation (design system, mobile architecture, web console, responsive guide, component library)
5. Write completion report

## Preservation Rules

- No database changes
- No backend rewrites
- All 747 existing tests preserved
- Widget registry (47 types) untouched
- Rule engine (39 node types) untouched
- Authentication, RLS, MQTT infrastructure preserved
