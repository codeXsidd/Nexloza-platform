# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.x.x   | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in NexLoza, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

1. Email: **security@nexloza.com** (or open a private GitHub Security Advisory)
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgement** within 48 hours
- **Assessment** within 7 days
- **Fix or mitigation** within 30 days for confirmed vulnerabilities
- Credit in the release notes (unless you prefer anonymity)

### Scope

The following are in scope:

- Authentication and authorization bypasses
- Cross-user data access (project/device isolation failures)
- MQTT credential exposure or replay attacks
- Insecure device command execution
- AI assistant permission bypasses
- Secret exposure in logs, responses, or Git history
- SQL injection, XSS, or CSRF in Edge Functions
- Insecure OTA firmware delivery

### Out of Scope

- Denial-of-service attacks against local development setups
- Issues in third-party dependencies (report upstream, then notify us)
- Social engineering

## Security Best Practices for Deployers

- Never commit `.env` files with real credentials
- Use TLS for MQTT in production (`mqtts://`)
- Rotate device credentials periodically
- Enable Row Level Security on all Supabase tables
- Use least-privilege IAM roles for AWS Bedrock
- Review audit logs regularly
- Keep dependencies updated
