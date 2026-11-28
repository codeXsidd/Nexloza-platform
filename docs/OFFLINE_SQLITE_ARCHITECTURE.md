# SQLite offline storage

SQLite stores account-scoped, last-known snapshots and the project edit outbox. Supabase remains the authority for authorization and concurrent edits.

## Driver and platform support

The implementation uses `sqlite3` 3.4.0 directly. Drift was considered for its typed schema, migration tooling, and browser worker support. The existing repositories already use typed domain entities, and the offline schema stores query snapshots and a small transactional outbox. Direct bindings keep that boundary small and avoid introducing generated models for a second representation of the same data.

Android, iOS, and desktop use the package's verified native assets and the application support directory. Flutter Web uses the matching upstream WebAssembly module and an IndexedDB filesystem. An exclusive Web Lock prevents independent in-memory SQLite mirrors from writing the same browser database. A second tab or unsupported browser can use Supabase online while local storage is unavailable. Serve the Web build over a secure origin or localhost. Browser storage is subject to site storage policy and eviction. Native storage is protected by the application sandbox. The database is plaintext.

The web assembly is the upstream `sqlite3-3.4.0/sqlite3.wasm` release asset. Its committed SHA-256 is `41cf968998241465d8b1dfffb1eb60dd10c35de5022a3647e14174ea3af84143`. Update the locked package and assembly together. [Upstream release](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-3.4.0)

## Schema and repository behavior

| SQLite table | Contents and limits |
| --- | --- |
| `snapshots` | Account, resource kind, scope, and query form the key. Existing repositories populate organization and project lists/details, device metadata, sensor and actuator capabilities, dashboards and widget configurations, reported twin state, and fetched historical telemetry. Opening device templates snapshots the bundled catalogue. |
| `outbox` | Project edit, account, local operation UUID, expected server version, attempt count, and enqueue timestamp. One pending edit per account/project. |
| `sync_conflicts` | A rejected or stale edit moved from the outbox in the same transaction. The Projects screen reports pending and conflict counts. |
| `sync_metadata` | Last settlement time per account. |

The SQLite schema is initialized transactionally at user version 1. A newer version is rejected before use. The original SharedPreferences queue used no account identity. Its serialized model remains readable for compatibility, and the app does not adopt or replay those entries. SharedPreferences still serves unrelated app settings.

Repositories refresh from Supabase first. They fall back to a matching cached query on a transport error. Authorization and validation errors surface from the server. New reads and providers that hold cached records check the active account. Snapshots expire after seven days, with a 48-hour limit for telemetry. Cache writes enforce a 256 KiB per-snapshot limit, 40 telemetry queries and 400 snapshots per account, and at most five cached accounts. Pending edits and conflicts are retained separately.

The cache strips secret-like keys recursively before serialization. Authentication sessions, passwords, service-role credentials, device credential records, and other secret stores are outside SQLite. Do not put secrets in user-defined labels, descriptions, or widget settings.

## Replay and conflicts

Project edits can queue the name, description, category, and active flag when a transport failure occurs and the account has a cached project version. The preview overlays the pending changes on a matching version. Startup and reconnect use the same Riverpod sync controller.

The replay RPC verifies that the authenticated identity matches the queued account and that the current user still has project update permission. It locks the project, checks the expected version, and commits an operation receipt with the edit. A retry after a committed response was lost returns the receipt. A stale version or revoked permission produces a conflict record. Transport errors retain the operation and increment the attempt counter.

Device commands and other mutations stay online. Conflict records are retained and counted. An interactive conflict review and retry screen is a separate follow-up. The hosted Chrome smoke test verified IndexedDB persistence across a close/reopen, single-writer locking, and account isolation. Windows Android runtime reconnect remains unverified. [Hosted validation](https://github.com/codeXsidd/Nexloza-platform/actions/runs/46155132303)
