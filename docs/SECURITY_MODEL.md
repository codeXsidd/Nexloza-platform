# Security Model

> NexIoza platform security architecture — Phase 2.

## Authentication

- **Provider**: Supabase Auth (email/password)
- **Session management**: JWT tokens with expiry checking
- **Token refresh**: Automatic via `refreshSession()` on app launch
- **Expired session handling**: Router redirect checks `session.expiresAt` and redirects to login

## Authorization

### Role Hierarchy

**Organization roles**: owner > admin > member
- **owner**: full control, can transfer ownership, delete org
- **admin**: can rename org, manage members (except owner)
- **member**: read access

**Project roles**: owner > admin > editor > viewer
- **owner/admin**: full control, manage members
- **editor**: can modify project data
- **viewer**: read-only access

### Key Rule
Project membership is independent — org membership does NOT automatically grant project access. Exception: org owner can see all org projects via RLS.

## Row Level Security

### Design Principles
1. All tables have RLS enabled
2. SELECT policies allow members to read their scoped data
3. All INSERT/UPDATE/DELETE policies block direct mutations (`USING(false)`)
4. All writes go through RPC functions (SECURITY INVOKER wrappers → SECURITY DEFINER implementations)
5. All SECURITY DEFINER functions use `SET search_path = ''` to prevent search_path injection

### Policy Count
- 32 RLS policies across all tables
- 16 public API wrapper functions
- 16 private implementation functions
- 5 private RLS helper functions

## Optimistic Concurrency

All mutable entities (profiles, organizations, projects) have a `version` column with an `increment_version()` trigger. Update operations require `_expected_version` — if the stored version doesn't match, the update fails (prevents lost updates).

## Invitation Security

- Invitation tokens are SHA-256 hashed before storage
- Raw token returned once at creation, never stored
- Tokens have expiration dates
- Expired invitations are cleaned up via trigger
- Only admins/owners of the target entity can create invitations

## Offline Security

- Local SQLite database (via Drift) stores cached data
- Pending mutations queued locally with idempotency keys
- Conflict detection compares local version against remote before push
- Failed mutations retry up to 3 times before marking as failed

## Secrets Management

- No service-role keys in Flutter code
- Only the public anon key is embedded (via `String.fromEnvironment`)
- `.env` files are gitignored
- `.env.example` contains placeholder values only
- Supabase Storage policies restrict avatar uploads to authenticated users

## Audit Logging

All mutations are logged to `audit_logs` table with:
- Actor ID, action type, entity type/ID
- Metadata payload (JSONB)
- Timestamp
- Immutable (insert-only, no update/delete)
