# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | Yes                |

## Reporting a Vulnerability

If you discover a security vulnerability in NexIoza, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please email: **security@nexioza.io** (or open a private security advisory on GitHub).

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgement**: Within 48 hours
- **Initial assessment**: Within 5 business days
- **Fix timeline**: Depends on severity, typically within 30 days

### Scope

The following are in scope:

- NexIoza Flutter application
- Supabase backend (Edge Functions, RLS policies)
- MQTT authentication and authorization
- Device provisioning and credential management
- AI assistant security (prompt injection, unauthorized actions)
- API endpoints and webhooks

### Out of Scope

- Third-party services (Supabase infrastructure, AWS, Firebase)
- Social engineering attacks
- Denial of service attacks
