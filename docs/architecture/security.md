# Nexloza — Security Architecture

## Principles

1. **Defense in depth** — multiple layers of security, never trust a single boundary
2. **Least privilege** — every actor (user, device, service) gets only the permissions it needs
3. **Zero trust for devices** — device identity and ownership verified on every request
4. **Backend authorization** — never rely on client-side checks alone
5. **Secrets never in code** — all credentials in environment variables, never committed

## Authentication

### User Authentication (Supabase Auth)

```
User ──► Supabase Auth ──► JWT (access + refresh)
              │
              ▼
         PostgreSQL (RLS enforced via auth.uid())
```

- Email/password registration with email verification
- Password reset via secure email link
- JWT tokens with configurable expiry (default: 1 hour access, 7 days refresh)
- Refresh token rotation — each refresh invalidates the previous token
- Session management with secure storage (flutter_secure_storage on mobile, httpOnly cookies on web)

### Device Authentication

```
Device ──► POST /device-auth ──► Verify API key + secret hash
                                        │
                                        ▼
                                 Generate short-lived MQTT JWT
                                        │
                                        ▼
Device ──► MQTT CONNECT (JWT) ──► Broker validates token
```

- Each device receives a unique API key (UUID) and secret (random 256-bit)
- Secret is stored as a bcrypt hash — never in plaintext
- Device auth endpoint returns a short-lived MQTT JWT (default: 24 hours)
- MQTT JWT encodes: device_id, project_id, allowed topics
- Credentials can be rotated without device downtime (old + new valid during transition)
- Credentials can be revoked instantly by setting `is_active = false`

### API Key Authentication (Developer APIs)

- Project-scoped API keys for webhook integrations and external services
- Keys are hashed at rest (SHA-256)
- Rate-limited per key (configurable, default: 100 req/min)
- Scoped to specific operations (read-only, read-write, admin)

## Authorization

### Row Level Security (RLS)

Every table has RLS enabled. Policies enforce:

| Actor | Access |
|-------|--------|
| User | Own profile only |
| Project owner | Full CRUD on project and all resources |
| Project admin | Full CRUD except project deletion |
| Project developer | Read/write on devices, sensors, actuators, commands, dashboards, automations |
| Project viewer | Read-only on all project resources |
| Non-member | No access to any project resource |
| Service role | Used only by Edge Functions for system operations (telemetry ingest, automation execution) |

### Project Isolation

- All device, sensor, actuator, telemetry, dashboard, automation, and integration data is scoped to a project
- RLS policies check `project_id` membership on every query
- Cross-project access is impossible without explicit membership
- Organization-level access provides a convenience layer but does not bypass project-level checks

## MQTT Security

### Transport Layer

- **TLS 1.2+** required for production (port 8883)
- Self-signed certificates acceptable for development; CA-signed required for production
- Client certificate authentication available for high-security deployments
- Unencrypted MQTT (port 1883) available for local development only

### Topic ACL

Devices can only access topics scoped to their own identity:

| Operation | Topic Pattern | Allowed |
|-----------|---------------|---------|
| PUBLISH | `nexloza/{project_id}/{device_id}/telemetry/#` | Own device only |
| PUBLISH | `nexloza/{project_id}/{device_id}/state` | Own device only |
| PUBLISH | `nexloza/{project_id}/{device_id}/heartbeat` | Own device only |
| SUBSCRIBE | `nexloza/{project_id}/{device_id}/commands` | Own device only |
| SUBSCRIBE | `nexloza/{project_id}/{device_id}/ota` | Own device only |

- Device cannot publish to another device's topics
- Device cannot subscribe to other devices' telemetry
- Backend services use a superuser account for cross-device operations

### Message Validation

- Maximum payload size: 256 KB
- JSON schema validation on telemetry ingest
- Command replay protection via unique command IDs and expiry timestamps
- Rate limiting per device (configurable, default: 60 messages/min)

## Edge Function Security

### Request Validation

- All Edge Functions validate the JWT from the `Authorization` header
- Device endpoints validate device credentials
- Input validation on all request bodies (type checking, length limits, allowed values)
- CORS configured to allow only the Nexloza app origin

### Service Role Usage

Edge Functions use the Supabase service role key for:
- Writing telemetry on behalf of authenticated devices
- Executing automation actions
- Sending notifications

The service role key is never exposed to clients. It is stored as an environment variable in the Edge Function runtime.

### AWS Bedrock Security

- AWS credentials stored as Edge Function environment variables
- IAM role scoped to `bedrock:InvokeModel` on specific model ARNs only
- No S3, EC2, Lambda, or other AWS service access
- Request/response logging for audit (sensitive content redacted)
- Rate limiting: configurable per-user and per-project limits
- Cost controls: maximum tokens per request, daily budget per project

## AI Safety

### Tool Calling Constraints

- AI tool definitions are narrowly scoped (get_device_status, get_sensor_readings, etc.)
- AI cannot execute arbitrary commands, SQL, or MQTT publications
- Device-control tools (request_device_command) require user confirmation before execution
- All tool calls are logged in the audit trail
- AI-generated automation rules are saved as drafts — user must explicitly approve and enable

### Prompt Security

- System prompts are never exposed to the user or in API responses
- User messages are sanitized before inclusion in prompts
- AI responses are validated before executing any side effects
- No prompt injection vectors: user input is clearly delimited in the prompt structure

## Secret Management

### Environment Variables

All secrets are stored as environment variables, never in code:

| Secret | Location | Purpose |
|--------|----------|---------|
| `SUPABASE_URL` | .env | Supabase project URL |
| `SUPABASE_ANON_KEY` | .env | Public API key (safe for client) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function env | Server-side operations |
| `MQTT_BROKER_URL` | .env | MQTT broker address |
| `MQTT_ADMIN_USER` | Edge Function env | MQTT superuser |
| `MQTT_ADMIN_PASSWORD` | Edge Function env | MQTT superuser password |
| `AWS_ACCESS_KEY_ID` | Edge Function env | Bedrock access |
| `AWS_SECRET_ACCESS_KEY` | Edge Function env | Bedrock access |
| `AWS_REGION` | Edge Function env | Bedrock region |
| `BEDROCK_MODEL_ID` | Edge Function env | Claude model identifier |

### Git Security

- `.env` files are in `.gitignore`
- `.env.example` contains only placeholder values
- Pre-commit hook (optional) scans for potential secrets
- CI/CD uses GitHub Secrets for deployment credentials

## Security Checklist

- [ ] All RLS policies tested with multiple users
- [ ] Device credentials cannot be used across projects
- [ ] MQTT TLS enabled in production
- [ ] No secrets in git history
- [ ] API rate limiting configured
- [ ] JWT expiry set appropriately
- [ ] Device credential rotation tested
- [ ] AI tool calling permissions verified
- [ ] Audit logging captures all sensitive operations
- [ ] Input validation on all external-facing endpoints
- [ ] CORS restricted to known origins
- [ ] Webhook signatures verified
- [ ] OTA firmware hashes validated
- [ ] Password policy enforced (minimum 8 characters)
- [ ] Session invalidation on password change
