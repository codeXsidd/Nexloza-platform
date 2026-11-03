# Database Schema

> PostgreSQL schema design for NexIoza — Phase 2.

## Overview

NexIoza uses PostgreSQL 17 via Supabase with a two-schema security model:
- **`public`** schema: tables and SECURITY INVOKER API wrapper functions
- **`private`** schema: SECURITY DEFINER implementation functions with `SET search_path = ''`

All direct mutations are blocked via RLS (`USING(false)` / `WITH CHECK(false)`). All writes go through RPC functions.

## Tables

### profiles
Stores user profile data. Auto-created via `handle_new_user()` trigger on `auth.users` insert.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | References auth.users |
| display_name | text | Default '' |
| avatar_url | text | Nullable |
| version | integer | Optimistic concurrency |
| created_at | timestamptz | |
| updated_at | timestamptz | Auto-updated via trigger |

### organizations
Multi-tenant organizations.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | Default gen_random_uuid() |
| name | text | NOT NULL |
| owner_id | uuid | References auth.users |
| version | integer | Optimistic concurrency |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### organization_members
Junction table for org membership with roles.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| organization_id | uuid FK | |
| user_id | uuid FK | |
| role | text | owner, admin, member |
| created_at | timestamptz | |

### projects
IoT projects belonging to organizations.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| organization_id | uuid FK | |
| name | text | |
| description | text | Nullable |
| category_id | uuid FK | Nullable, references project_categories |
| icon | text | Default 'folder' |
| color | text | Default '#0891B2' |
| is_template | boolean | Default false |
| template_id | uuid | Nullable, source template |
| metadata | jsonb | Nullable |
| version | integer | Optimistic concurrency |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### project_members
Junction table for project membership. Independent of org membership.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| project_id | uuid FK | |
| user_id | uuid FK | |
| role | text | owner, admin, editor, viewer |
| created_at | timestamptz | |

### invitations
Token-based invitations to organizations or projects.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| entity_type | text | 'organization' or 'project' |
| entity_id | uuid | |
| invited_email | text | |
| invited_by | uuid FK | |
| token_hash | text | SHA-256 hash of raw token |
| role | text | |
| status | text | pending, accepted, rejected, cancelled |
| expires_at | timestamptz | |
| created_at | timestamptz | |

### project_categories
Seed data for project classification (10 categories).

### audit_logs
Immutable audit trail for all mutations.

## Private Schema

### Helper Functions (SECURITY DEFINER)
- `private.is_org_member(org_id, user_id)` — membership check
- `private.is_org_role(org_id, user_id, roles[])` — role check
- `private.is_project_member(project_id, user_id)` — membership check
- `private.is_project_role(project_id, user_id, roles[])` — role check
- `private.owns_org(org_id, user_id)` — ownership check

### Infrastructure
- `private.idempotency_ledger` — server-side idempotency tracking
- `private.change_log` — BIGSERIAL sync cursors for offline sync

## Migrations

12 forward-only migrations in `backend/supabase/migrations/`:

1. `20261103000001_create_profiles.sql`
2. `20261103000002_create_organizations.sql`
3. `20261103000003_create_project_categories.sql`
4. `20261103000004_create_projects.sql`
5. `20261103000005_create_audit_log.sql`
6. `20261103000006_create_private_schema.sql`
7. `20261103000007_add_version_columns.sql`
8. `20261103000008_cleanup_triggers.sql`
9. `20261103000009_create_invitations.sql`
10. `20261103000010_rls_overhaul.sql`
11. `20261103000011_private_implementations.sql`
12. `20261103000012_public_api_wrappers.sql`

## RLS Policies

All tables have RLS enabled. SELECT policies allow members to read their own data. All INSERT/UPDATE/DELETE policies use `USING(false)` / `WITH CHECK(false)` to block direct mutations — all writes go through 16 public RPC wrapper functions.

## Public API Functions

16 SECURITY INVOKER wrappers that call private SECURITY DEFINER implementations:

- `create_organization`, `update_organization`, `delete_organization`
- `create_project`, `update_project`, `delete_project`
- `create_project_from_template`
- `update_profile`
- `create_invitation`, `accept_invitation`, `reject_invitation`, `cancel_invitation`
- `update_member_role`, `remove_member`
- `transfer_org_ownership`
- `delete_own_account`
