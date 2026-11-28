# Virtual IoT runtime results

| Check | Evidence |
| --- | --- |
| NanoMQ authentication and scoped ACL | Passed on the real 0.22.6 broker in Codex Cloud. Authenticated publish/subscribe and reconnect passed. Anonymous and wrong-password authentication were rejected. A permitted observer received its control message on a second project topic and did not receive the first project's attempted publish. |
| Database migration and RLS | All 21 migrations applied on PostgreSQL 15 with a minimal Auth schema shim. The existing 14 fixture checks passed, plus real authenticated-role checks for project isolation, virtual-only writes, and duplicate batch handling. This check did not exercise Supabase Auth or the API gateway. |
| Supabase stack in Codex Cloud | Blocked. The Supabase CLI's image pull from `public.ecr.aws` returned `Forbidden`. |
| Disposable Supabase gateway and Edge Functions | Passed on GitHub Actions. The CLI started the gateway, applied all 21 migrations, and ran the existing SQL suite with the new authenticated-role checks. |
| MQTT to Edge ingestion to Supabase | Passed on GitHub Actions. An authenticated fixture published temperature and humidity in an identified batch twice, then replayed it through the Edge Function. The project owner saw one row per sensor, with exact values and the same UTC timestamp and message UUID. Another signed-in user could not read the rows. Invalid device credentials and a mismatched device identity were rejected. |
| Flutter regression | 881 passed and no failures reported. Locked dependencies, formatting, analysis, web release and debug APK passed. |
| Flutter simulator on Windows | Unrun. Use [the local kit](../LOCAL_DEVELOPMENT_SETUP.md) to compare message ID, UTC timestamp, value, and sensor key in the UI and stored row. |
| Soil moisture, relay, LED, fan speed, command acknowledgements and online/offline transition | Unrun end to end. The current worker and broker fixture are scoped to telemetry for one device. No last-will or command round trip was verified. |
| Physical hardware | Untested. |

The simulator's direct Supabase mode and MQTT mode are mutually exclusive per run. Both write a message UUID alongside each sensor key. A database constraint protects that tuple against retries. Historic clients may still submit readings without message IDs.

[Passing hosted run 46151429807](https://github.com/codeXsidd/Nexloza-platform/actions/runs/46151429807) validated the Flutter and backend changes at `481c820`. Its broker publisher was the integration harness. The Flutter UI matching check requires the Windows emulator.

## Advanced virtual-device run

The hosted harness uses two Supabase users, organizations, projects and device credentials with exact NanoMQ ACLs. The broker participant in this evidence is the Python test device.

| Check | Observed result |
| --- | --- |
| Temperature, humidity and soil moisture | Values persisted in the intended account and device. Replayed temperature/humidity batches retained one row per sensor/message. Another account could not read the soil rows. |
| Relay and LED | Both ON and OFF reached the command topic and produced a matching acknowledgement, result and reported value. |
| Fan speed, brightness and servo angle | The test exercised fan 60, brightness 45 and servo 90 for registered capabilities. Each value matched the stored reported twin state. |
| Command lifecycle | Commands remained sent before acknowledgement. Duplicate requests reused the command ID and duplicate acknowledgements kept one result. Device rejection produced a failure. An unacknowledged command expired without a result. |
| Authorization | Invalid device credentials and device IDs were rejected. Cross-project requests and a viewer issuing a command for a visible device were rejected. |
| Availability | An interrupted MQTT connection triggered the retained offline Last Will. The test client automatically reconnected and returned to online. |
| Flutter and physical devices | Windows `emulator-5554`, physical relay/LED/fan/servo hardware, and native runtime reconnect on the emulator are unrun. |

[Hosted protocol evidence](https://github.com/codeXsidd/Nexloza-platform/actions/runs/46154220702)
