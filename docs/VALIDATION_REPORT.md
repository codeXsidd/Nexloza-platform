# Nexloza — Supabase-First Database & Backend Validation Report

**Date:** 2026-11-07
**Validator:** Claude Opus 4.6 (automated audit)
**Scope:** All 14 migrations, 6 Edge Functions, 4 Flutter repositories, MQTT architecture

---

## 1. ER Diagram (Text)

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│   auth.users     │────▶│     profiles          │     │  organizations  │
│   (Supabase)     │     │ id (PK, FK→auth.users)│     │ id (PK)         │
└─────────────────┘     │ email, full_name       │     │ name, slug      │
                        │ avatar_url, phone      │     │ created_by→prof │
                        │ timezone, preferences  │     └────────┬────────┘
                        └──────────┬─────────────┘              │
                                   │                   ┌────────▼────────┐
                                   │                   │ organization_   │
                                   ├──────────────────▶│   members       │
                                   │                   │ org_id, user_id │
                                   │                   │ role (enum)     │
                                   │                   └─────────────────┘
                        ┌──────────▼─────────────┐
                        │      projects           │
                        │ id (PK)                 │
                        │ name, category (enum)   │
                        │ organization_id→orgs    │
                        │ owner_id→profiles       │
                        │ device_limit, is_active │
                        └──────────┬─────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
┌─────────▼──────────┐  ┌─────────▼──────────┐  ┌─────────▼──────────┐
│  project_members   │  │     devices         │  │   dashboards       │
│ project_id, user_id│  │ id (PK)             │  │ id (PK)            │
│ role (enum)        │  │ project_id→projects │  │ project_id→projects│
└────────────────────┘  │ name, device_type   │  │ name, layout       │
                        │ hardware_platform   │  └─────────┬──────────┘
                        │ is_online, last_seen│            │
                        └──────────┬──────────┘  ┌─────────▼──────────┐
                                   │             │ dashboard_widgets  │
          ┌────────────────────────┼──────┐      │ dashboard_id→dash  │
          │                        │      │      │ widget_type (enum) │
          │                        │      │      └────────────────────┘
┌─────────▼──────────┐  ┌─────────▼──────┐
│ device_credentials │  │ device_groups   │     ┌────────────────────┐
│ device_id→devices  │  │ project_id→proj │     │    automations     │
│ api_key (unique)   │  └────────┬───────┘     │ id (PK)            │
│ secret_hash        │           │             │ project_id→projects│
│ is_active, expires │  ┌────────▼───────┐     │ name, is_enabled   │
└────────────────────┘  │ device_group_  │     │ priority, cooldown │
                        │    members     │     └──────────┬─────────┘
                        │ (composite PK) │                │
                        └────────────────┘     ┌──────────┼──────────┐
                                               │          │          │
┌────────────────────┐              ┌──────────▼───┐ ┌────▼─────┐ ┌─▼──────────┐
│ sensor_definitions │              │ auto_triggers │ │auto_cond │ │auto_actions│
│ device_id→devices  │              │ trigger_type  │ │cond_type │ │action_type │
│ project_id→projects│              │ config (jsonb)│ │config    │ │config      │
│ sensor_type (enum) │              └───────────────┘ └──────────┘ └────────────┘
│ telemetry_key      │                      │
│ thresholds (lo/hi) │              ┌───────▼───────┐
└────────────────────┘              │ auto_executions│
                                    │ trigger_data   │
┌────────────────────┐              │ status, timing │
│actuator_definitions│              └────────────────┘
│ device_id→devices  │
│ actuator_type      │    ┌─────────────────┐    ┌─────────────────┐
│ control_type       │    │     scenes      │    │  notifications  │
│ command_key        │    │ project_id→proj │    │ user_id→profiles│
└────────────────────┘    │ name, is_active │    │ project_id→proj │
                          └────────┬────────┘    │ title, body     │
┌────────────────────┐             │             │ category, sev.  │
│    telemetry       │    ┌────────▼────────┐    │ is_read         │
│ id (bigserial PK)  │    │  scene_actions  │    └─────────────────┘
│ device_id→devices  │    │ scene_id→scenes │
│ sensor_key         │    │ device_id→dev   │    ┌─────────────────┐
│ value_numeric/text │    │ actuator_id→act │    │ notif_preferences│
│ recorded_at        │    │ target_state    │    │ user_id→profiles│
└────────────────────┘    └─────────────────┘    │ category, flags │
                                                 └─────────────────┘
┌────────────────────┐    ┌─────────────────┐
│  device_commands   │    │  integrations   │    ┌─────────────────┐
│ device_id→devices  │    │ project_id→proj │    │ ai_conversations│
│ issued_by→profiles │    │ type (enum)     │    │ user_id→profiles│
│ command_type       │    │ credentials_enc │    │ project_id→proj │
│ payload, status    │    └────────┬────────┘    │ title, model_id │
│ expires_at, retries│             │             └────────┬────────┘
└──────────┬─────────┘    ┌────────▼────────┐             │
           │              │integr_events    │    ┌────────▼────────┐
┌──────────▼─────────┐    │ integration_id  │    │   ai_messages   │
│  command_results   │    │ event_type      │    │ conversation_id │
│ command_id→cmds    │    │ payload, status │    │ role, content   │
│ device_id→devices  │    └─────────────────┘    │ tokens_used     │
│ success, result    │                           └─────────────────┘
└────────────────────┘
                          ┌─────────────────┐    ┌─────────────────┐
                          │  firmware_vers   │    │   audit_logs    │
                          │ project_id→proj │    │ id (bigserial)  │
                          │ device_type, ver │    │ user_id→profiles│
                          │ file_url, hash  │    │ project_id→proj │
                          └────────┬────────┘    │ action, resource│
                                   │             │ ip_address      │
                          ┌────────▼────────┐    └─────────────────┘
                          │ ota_deployments │
                          │ firmware_ver_id │
                          │ device_id/group │
                          │ status (enum)   │
                          └─────────────────┘
```

**Total tables:** 28
**Total enums:** 14

---

## 2. Migration Audit Report

### 2.1 Migration Summary

| # | File | Tables | Enums | RLS | Indexes | Status |
|---|------|--------|-------|-----|---------|--------|
| 00001 | profiles | 1 | 0 | ✅ | 1 | ✅ Clean |
| 00002 | organizations | 2 | 1 | ✅ | 3 | ⚠️ No auto-add trigger |
| 00003 | projects | 2 | 2 | ✅ | 5 | ✅ Clean |
| 00004 | devices | 4 | 1 | ✅ | 6 | ✅ Clean |
| 00005 | sensors_actuators | 2 | 3 | ✅ | 6 | ⚠️ Denorm project_id |
| 00006 | telemetry | 3 | 1 | ✅ | 5 | ⚠️ No partition/retention |
| 00007 | dashboards | 2 | 1 | ✅ | 2 | ✅ Clean |
| 00008 | automations | 5 | 4 | ✅ | 6 | ✅ Clean |
| 00009 | scenes | 2 | 0 | ✅ | 2 | ✅ Clean |
| 00010 | notifications | 2 | 2 | ✅ | 2 | ⚠️ No DELETE policy |
| 00011 | integrations | 2 | 1 | ✅ | 0 | ❌ Broken RLS, no indexes |
| 00012 | ai | 2 | 1 | ✅ | 2 | ✅ Clean |
| 00013 | audit | 1 | 0 | ✅ | 2 | ❌ Broken RLS |
| 00014 | firmware | 2 | 1 | ✅ | 0 | ❌ Broken RLS, no indexes |
| **00015** | **validation_fixes** | **0** | **0** | **fix** | **7** | **NEW — all fixes** |

### 2.2 Issues Found & Fixed (Migration 00015)

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| 1 | **CRITICAL** | Integrations, audit_logs, firmware RLS policies use raw `project_members` table — project owners excluded | Rewrote all policies to check `projects.owner_id` OR `project_members` |
| 2 | **HIGH** | No auto-add trigger for org creator → org creator can't see own org | Added `handle_new_organization()` trigger |
| 3 | **HIGH** | No DELETE policy on notifications → users can't dismiss notifications | Added `"Users can delete own notifications"` policy |
| 4 | **HIGH** | Audit logs: users can't see their own user-level logs (project_id IS NULL) | Added user_id check for user-scoped logs |
| 5 | **MEDIUM** | Missing 7 indexes on integrations, firmware, OTA, telemetry tables | Created all indexes |
| 6 | **MEDIUM** | No telemetry retention/cleanup mechanism | Added `cleanup_old_telemetry(days)` function |
| 7 | **MEDIUM** | No audit log retention mechanism | Added `cleanup_old_audit_logs(days)` function |
| 8 | **MEDIUM** | No rate-limiting for telemetry ingestion | Added `check_telemetry_rate_limit()` function |
| 9 | **LOW** | sensor/actuator `project_id` can go out of sync with `device.project_id` | Added consistency check triggers |

---

## 3. Security Report

### 3.1 RLS Coverage

| Table | RLS | SELECT | INSERT | UPDATE | DELETE | Notes |
|-------|-----|--------|--------|--------|--------|-------|
| profiles | ✅ | own | own | own | — | No delete (cascade from auth) |
| organizations | ✅ | members | auth'd | admin | owner | |
| organization_members | ✅ | members | admin | admin | admin | |
| projects | ✅ | members | owner | owner/admin | owner | |
| project_members | ✅ | members | dev+ | owner/admin | owner/admin | |
| devices | ✅ | members | dev+ | dev+ | dev+ | |
| device_credentials | ✅ | dev+ | dev+ | dev+ | dev+ | |
| device_groups | ✅ | members | dev+ | dev+ | dev+ | |
| device_group_members | ✅ | members | dev+ | dev+ | dev+ | |
| sensor_definitions | ✅ | members | dev+ | dev+ | dev+ | |
| actuator_definitions | ✅ | members | dev+ | dev+ | dev+ | |
| telemetry | ✅ | members | service | — | — | Immutable via service role |
| device_commands | ✅ | members | dev+ | dev+ | — | |
| command_results | ✅ | members | service | — | — | Immutable |
| dashboards | ✅ | members | dev+ | dev+ | dev+ | |
| dashboard_widgets | ✅ | members | dev+ | dev+ | dev+ | |
| automations | ✅ | members | dev+ | dev+ | dev+ | |
| automation_triggers | ✅ | members | dev+ | dev+ | dev+ | |
| automation_conditions | ✅ | members | dev+ | dev+ | dev+ | |
| automation_actions | ✅ | members | dev+ | dev+ | dev+ | |
| automation_executions | ✅ | members | service | — | — | Immutable |
| scenes | ✅ | members | dev+ | dev+ | dev+ | |
| scene_actions | ✅ | members | dev+ | dev+ | dev+ | |
| notifications | ✅ | own | service | own | **own** ✅ | DELETE added in 00015 |
| notification_preferences | ✅ | own | own | own | own | |
| integrations | ✅ | **members** ✅ | admin | admin | admin | Fixed in 00015 |
| integration_events | ✅ | **members** ✅ | service | — | — | Fixed in 00015 |
| ai_conversations | ✅ | own | own | own | own | |
| ai_messages | ✅ | own | own | own | own | |
| audit_logs | ✅ | **admin+own** ✅ | service | — | — | Fixed in 00015 |
| firmware_versions | ✅ | **members** ✅ | admin | admin | admin | Fixed in 00015 |
| ota_deployments | ✅ | **members** ✅ | admin | admin | admin | Fixed in 00015 |

**All 28 tables have RLS enabled. All user-accessible operations have policies.**

### 3.2 Security Checklist

- [x] RLS enabled on all user-accessible tables
- [x] Service-role key never exposed to Flutter (only in Edge Functions env)
- [x] Device credentials use hashed secrets (SHA-256)
- [x] Per-device MQTT credentials (via device-auth edge function)
- [x] Organization and project permissions validated through helper functions
- [x] Edge Functions validate auth headers before processing
- [x] Telemetry-ingest now requires device API key + secret (was unauthenticated)
- [x] Webhook handler now validates HMAC signatures
- [x] Rate limiting added for telemetry ingestion
- [x] Audit logging table exists (insert via service role only)
- [x] Integration credentials stored in `credentials_encrypted` field
- [x] Constant-time hash comparison in device-auth to prevent timing attacks
- [x] Input validation on all Edge Function payloads
- [x] CORS headers present on all Edge Functions

### 3.3 Remaining Recommendations

1. **Upgrade SHA-256 to bcrypt/argon2** for device secret hashing (marked TODO in code)
2. **Restrict CORS origins** to your domain for user-facing functions (currently `*`)
3. **Implement actual encryption** for `integrations.credentials_encrypted` (server-side)
4. **Add pg_cron** for scheduled telemetry/audit cleanup (call `cleanup_old_telemetry()`)
5. **Consider partitioning** the telemetry table by month when data exceeds 10M rows

---

## 4. Edge Function Audit

| Function | Auth | Validation | Error Handling | Changes Made |
|----------|------|------------|----------------|--------------|
| device-auth | API key + secret | ✅ | ✅ | Added constant-time hash comparison |
| telemetry-ingest | **API key + secret** ✅ | **Payload size limit, key format, rate limit** ✅ | ✅ | Complete rewrite — was unauthenticated |
| device-command | JWT + RLS | ✅ | ✅ | No changes needed |
| ai-assistant | JWT + RLS | ✅ | ✅ | No changes needed |
| automation-engine | Service-only | **Input type validation** ✅ | ✅ | Added input validation, CORS, hourly exec limit, action logging |
| webhook-handler | **HMAC signature** ✅ | **JSON validation** ✅ | ✅ | Added HMAC verification, JSON parse safety |

---

## 5. Flutter Repository Audit

| Repository | Pagination | Auth Check | Error Types | Changes Made |
|------------|------------|------------|-------------|--------------|
| ProjectRepository | **✅ Added** | via Supabase | PostgrestException | Added `page`/`pageSize` params |
| DeviceRepository | **✅ Added** | via Supabase | PostgrestException | Added `page`/`pageSize` params |
| AutomationRepository | **✅ Added** | via Supabase | PostgrestException | Added `page`/`pageSize` params |
| NotificationRepository | ✅ Had limit(50) | Explicit userId check | PostgrestException + AuthFailure | No changes needed |

---

## 6. MQTT Architecture Verification

| Component | Status | Notes |
|-----------|--------|-------|
| EMQX broker in docker-compose | ✅ | Ports 1883, 8083 (WS), 18083 (dashboard) |
| Topic structure | ✅ | `nexloza/{project_id}/{device_id}/{channel}` |
| Device-auth returns MQTT config | ✅ | client_id, username, topic paths |
| Flutter MqttService | ✅ | Connection, pub/sub, reconnection, streams |
| MqttConstants | ✅ | Ports, keep-alive, topic builders |
| Per-device credentials | ✅ | device_credentials table with api_key + secret_hash |

---

## 7. Test Results

### Flutter

| Check | Result |
|-------|--------|
| `dart analyze lib/` | ✅ 0 issues |
| `dart analyze test/` | ✅ 0 issues |
| `flutter test` | ✅ 53/53 passed |
| `dart format --set-exit-if-changed` | ✅ 0 changes |
| `flutter build web --release` | ✅ Success |

### SQL RLS Integration Tests

Test file: `backend/supabase/tests/rls_integration_test.sql`

| Test | Verification |
|------|-------------|
| Org creator auto-added as owner | Trigger `handle_new_organization` |
| User B excluded from org_alpha | Membership isolation |
| Project ownership check | owner_id verification |
| Cross-project device isolation | project_id FK enforcement |
| Telemetry data isolation | Per-device via project membership |
| Notification user isolation | user_id = auth.uid() |
| AI conversation isolation | user_id = auth.uid() |
| Sensor project_id consistency | Trigger rejects mismatch |
| Rate limit helper | Returns true under limit |
| Telemetry retention cleanup | Removes rows older than N days |
| Device command isolation | Per-device via project membership |
| Audit log visibility | User-level + project admin check |

**12 tests covering tenant isolation, data integrity, and cleanup functions.**

---

## 8. Files Changed

### New Files
- `backend/supabase/migrations/00015_validation_fixes.sql` — All database fixes
- `backend/supabase/tests/rls_integration_test.sql` — RLS integration test suite

### Modified Files
- `backend/supabase/functions/telemetry-ingest/index.ts` — Device auth + rate limit
- `backend/supabase/functions/automation-engine/index.ts` — Input validation + CORS
- `backend/supabase/functions/webhook-handler/index.ts` — HMAC signature verification
- `backend/supabase/functions/device-auth/index.ts` — Constant-time hash comparison
- `app/lib/features/projects/data/project_repository.dart` — Pagination
- `app/lib/features/devices/data/device_repository.dart` — Pagination
- `app/lib/features/automations/data/automation_repository.dart` — Pagination
