# Contributing to NexLoza

Thank you for your interest in contributing to NexLoza! This guide will help you get started.

## Getting Started

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature or fix: `git checkout -b feat/my-feature`
4. **Make your changes** following the guidelines below
5. **Test** your changes thoroughly
6. **Commit** with a clear message following [Conventional Commits](https://www.conventionalcommits.org/)
7. **Push** to your fork and open a **Pull Request**

## Development Setup

See the [Quick Start](README.md#quick-start) section in the README for environment setup.

## Code Guidelines

### Flutter / Dart

- Follow the official [Dart Style Guide](https://dart.dev/effective-dart/style)
- Use `dart format` before committing
- Ensure `flutter analyze` passes with zero issues
- Write tests for new features and bug fixes
- Use Riverpod for state management
- Follow feature-first folder structure

### Backend (Supabase)

- Write database migrations, never modify the database manually
- Always add Row Level Security policies for new tables
- Test RLS policies to verify data isolation
- Document Edge Function APIs

### Firmware

- Follow Arduino coding conventions
- Test on actual hardware when possible; clearly label simulated tests
- Document pin configurations and wiring

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add soil moisture sensor widget
fix: correct MQTT reconnection on Wi-Fi dropout
docs: update ESP32 wiring guide
test: add RLS isolation tests for device_commands
chore: update Flutter dependencies
```

## Pull Request Process

1. Fill out the PR template completely
2. Link related issues
3. Ensure CI passes (lint, analyze, tests, build)
4. Request review from a maintainer
5. Address review feedback
6. Squash and merge when approved

## Reporting Issues

- Use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) template for bugs
- Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template for ideas
- Check existing issues before creating duplicates

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating.

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
