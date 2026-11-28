# Virtual IoT runtime results

| Check | Evidence |
| --- | --- |
| NanoMQ authentication and scoped ACL | Passed on the real 0.22.6 broker in Codex Cloud. Authenticated publish/subscribe and reconnect passed. Anonymous and wrong-password authentication were rejected. A permitted observer received its control message on a second project topic and did not receive the first project's attempted publish. |
| Database migration and RLS | All 21 migrations applied on PostgreSQL 15 with a minimal Auth schema shim. The existing 14 fixture checks passed, plus real authenticated-role checks for project isolation, virtual-only writes, and duplicate batch handling. This check did not exercise Supabase Auth or the API gateway. |
| Supabase stack in Codex Cloud | Blocked. The Supabase CLI's image pull from `public.ecr.aws` returned `Forbidden`. |
| MQTT to Edge ingestion to Supabase | GitHub-hosted integration run pending. The test requires a row from the broker before it attempts the HTTP replay. |
| Flutter simulator on Windows | Unrun. Use [the local kit](../LOCAL_DEVELOPMENT_SETUP.md) to compare message ID, UTC timestamp, value, and sensor key in the UI and stored row. |
| Humidity, soil moisture, relay, LED, fan speed, command acknowledgements and online/offline transition | Unrun end to end. The current worker and broker fixture are scoped to telemetry for one device. No last-will or command round trip was verified. |
| Physical hardware | Untested. |

The simulator's direct Supabase mode and MQTT mode are mutually exclusive per run. Both write a message UUID alongside each sensor key. A database constraint protects that tuple against retries. Historic clients may still submit readings without message IDs.
