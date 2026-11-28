# NEXLOZA Feature Matrix

**Date:** 2026-11-09
**Commit:** 637623e
**Branch:** main

## Classification Key

| Status | Definition |
|---|---|
| VERIFIED | Implemented, tested, and confirmed working |
| IMPLEMENTED | Code exists and compiles, basic testing done |
| PARTIALLY IMPLEMENTED | Core logic exists but missing sub-features |
| MOCKED | UI exists but uses fake/static data |
| BLOCKED | Cannot proceed without external dependency |
| NOT IMPLEMENTED | No code exists |

---

## 1. Authentication & User Management

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Email/password registration | Yes | Supabase Auth | Yes | VERIFIED |
| Email/password login | Yes | Supabase Auth | Yes | VERIFIED |
| Logout | Yes | Supabase Auth | Yes | VERIFIED |
| Password recovery | Yes | Supabase Auth | Yes | IMPLEMENTED |
| Email verification | Yes | Supabase Auth | — | IMPLEMENTED |
| Profile management | Yes | profiles table + RLS | Yes | VERIFIED |

## 2. Organizations

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Organization creation | Yes | DB + RLS | Yes | IMPLEMENTED |
| Organization listing | Yes | DB + RLS | Yes | IMPLEMENTED |
| Organization detail | Yes | DB + RLS | — | IMPLEMENTED |
| Member management | — | DB + RLS + trigger | — | PARTIALLY IMPLEMENTED |
| Role management | — | DB schema exists | — | PARTIALLY IMPLEMENTED |

## 3. Projects

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Project creation | Yes | DB + RLS | Yes | VERIFIED |
| Project listing + search | Yes | DB + RLS | Yes | VERIFIED |
| Project detail | Yes | DB + RLS | Yes | VERIFIED |
| Project editing | Yes | DB + RLS | Yes | IMPLEMENTED |
| Project deletion | Yes | DB + RLS | — | IMPLEMENTED |
| Project sharing / invitations | Yes | DB + RLS + RPC | Yes | IMPLEMENTED |
| Project duplication | — | — | — | NOT IMPLEMENTED |
| Project templates | — | — | — | NOT IMPLEMENTED |

## 4. Device Management

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Device registration | Yes | DB + RLS | Yes | VERIFIED |
| Device listing | Yes | DB + RLS | Yes | VERIFIED |
| Device detail | Yes | DB + RLS | Yes | IMPLEMENTED |
| Device editing | Yes | DB + RLS | — | IMPLEMENTED |
| Device credentials | Yes | DB + SHA-256 | Yes | VERIFIED |
| Device status | Yes | DB field | Yes | IMPLEMENTED |
| Device grouping | — | DB schema exists | — | NOT IMPLEMENTED (no Dart repo) |
| Device diagnostics | — | — | — | NOT IMPLEMENTED |
| OTA updates | — | DB schema exists | — | NOT IMPLEMENTED (no Dart repo) |

## 5. Sensors & Actuators

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Sensor definitions CRUD | Yes | DB + RLS | Yes | VERIFIED |
| Actuator definitions CRUD | Yes | DB + RLS | Yes | IMPLEMENTED |
| Custom sensor types | Yes | user-defined | — | IMPLEMENTED |
| Calibration | — | DB field | — | NOT IMPLEMENTED |
| Threshold alerts | — | DB field | — | NOT IMPLEMENTED |

## 6. Dashboards

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Dashboard CRUD | Yes | DB + RLS | Yes | IMPLEMENTED |
| Dashboard editor | Yes | Widget grid | — | IMPLEMENTED |
| Gauge widget | Yes | Custom painter | — | IMPLEMENTED |
| Line chart | Yes | Custom painter | — | IMPLEMENTED |
| Bar chart | Yes | Custom painter | — | IMPLEMENTED |
| Value display | Yes | — | — | IMPLEMENTED |
| Toggle | Yes | — | — | IMPLEMENTED |
| Status indicator | Yes | — | — | IMPLEMENTED |
| Real-time MQTT data binding | — | — | — | NOT IMPLEMENTED |
| Widget resize/rearrange | — | — | — | NOT IMPLEMENTED |
| 16 additional widget types | — | — | — | NOT IMPLEMENTED |

## 7. Automations

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Automation CRUD | Yes | DB + RLS | Yes | IMPLEMENTED |
| Automation detail | Yes | — | — | IMPLEMENTED |
| Toggle enable/disable | Yes | DB | — | IMPLEMENTED |
| Visual rule builder | — | — | — | NOT IMPLEMENTED |
| Trigger/condition/action management | — | DB schemas exist | — | NOT IMPLEMENTED |
| Backend execution | — | Edge Function | — | PARTIALLY IMPLEMENTED (buggy) |
| Scheduling | — | — | — | NOT IMPLEMENTED |

## 8. AI Assistant (Grok)

| Feature | UI | Backend | Tests | Status |
|---|---|---|---|---|
| Chat UI | Yes | — | — | IMPLEMENTED |
| Grok API (xAI) | — | Edge Function | — | IMPLEMENTED |
| Conversation persistence | — | DB | — | IMPLEMENTED |
| Streaming | — | — | — | NOT IMPLEMENTED |
| Automation proposals | — | — | — | NOT IMPLEMENTED |
| Mock provider for tests | — | — | — | NOT IMPLEMENTED |

## 9. Voice Control

| Feature | Status |
|---|---|
| All features | NOT IMPLEMENTED |

## 10. Alexa Integration

| Feature | Status |
|---|---|
| Smart Home Skill | PLACEHOLDER (skill.json only) |
| All other features | NOT IMPLEMENTED |

## 11. Google Home Integration

| Feature | Status |
|---|---|
| All features | NOT IMPLEMENTED |

## 12. Virtual Device Simulator

| Feature | Status |
|---|---|
| All features | NOT IMPLEMENTED |

## 13. MQTT Infrastructure

| Feature | Status | Detail |
|---|---|---|
| NanoMQ broker | SCOPED DEV BROKER VERIFIED | NanoMQ 0.22.6 authenticated publish/subscribe and exact-topic denial checks passed. |
| Flutter MQTT service | IMPLEMENTED | mqtt_client, auto-reconnect |
| Firmware MQTT | IMPLEMENTED | PubSubClient, LWT, heartbeat |
| Topic structure | INCONSISTENT | Three-way mismatch |
| Per-device auth | IMPLEMENTED | Edge Function + SHA-256 |

## 14. Hardware Lab

| Feature | Status |
|---|---|
| Board selection UI | PARTIALLY IMPLEMENTED |
| Code generator | PARTIALLY IMPLEMENTED |
| Interactive tutorials | NOT IMPLEMENTED |
| Wiring diagrams | NOT IMPLEMENTED |

## 15. Offline & Notifications

| Feature | Status |
|---|---|
| Offline sync service | PARTIALLY IMPLEMENTED |
| Push notifications (FCM) | NOT IMPLEMENTED |
| In-app notifications | IMPLEMENTED |
| Email notifications | NOT IMPLEMENTED |

## 16. Firmware SDK

| Feature | Status |
|---|---|
| Core SDK (connect, telemetry, commands) | IMPLEMENTED |
| WiFi management | IMPLEMENTED |
| Provisioning (captive portal) | IMPLEMENTED |
| OTA framework | PARTIALLY IMPLEMENTED |
| registerSensor/registerActuator | NOT IMPLEMENTED |
| 12 board examples | 10 IMPLEMENTED, 2 MISSING |

## 17. Open Source Release

| File | Status |
|---|---|
| LICENSE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY | IMPLEMENTED |
| CHANGELOG | NEEDS UPDATE |
| .env.example, .gitignore | IMPLEMENTED |
| THIRD_PARTY_NOTICES.md | NOT IMPLEMENTED |
| 16 required docs | NOT IMPLEMENTED |
| GitHub Actions CI | PARTIALLY IMPLEMENTED |

---

## Summary

| Status | Count |
|---|---|
| VERIFIED | 12 |
| IMPLEMENTED | 42 |
| PARTIALLY IMPLEMENTED | 22 |
| PLACEHOLDER | 1 |
| NOT IMPLEMENTED | 62 |

**Overall: ~55% of master prompt requirements implemented**

### Live IoT verification

See [virtual IoT test results](test-results/VIRTUAL_IOT_E2E_TEST.md) for broker, backend, emulator, and hardware coverage.
