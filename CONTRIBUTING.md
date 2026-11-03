# Contributing to NexIoza

Thank you for your interest in contributing to NexIoza. This guide will help you get started.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

- Use the [Bug Report](https://github.com/codeXsidd/nexioza-platform/issues/new?template=bug_report.md) issue template.
- Include steps to reproduce, expected behavior, and actual behavior.
- Include your Flutter version, device, and OS version.

### Suggesting Features

- Use the [Feature Request](https://github.com/codeXsidd/nexioza-platform/issues/new?template=feature_request.md) issue template.
- Describe the use case and proposed solution.

### Submitting Pull Requests

1. Fork the repository.
2. Create a feature branch from `main`: `git checkout -b feat/your-feature`.
3. Make your changes.
4. Run `flutter analyze` and `flutter test` in the `app/` directory.
5. Commit using conventional commit messages.
6. Push and open a pull request against `main`.

## Development Setup

### Prerequisites

- Flutter 3.47+
- Dart 3.13+
- Android SDK 34+
- Docker (optional, for local backend)

### Getting Started

```bash
cd app
flutter pub get
flutter run
```

### Running Tests

```bash
cd app
flutter test
```

### Running Analysis

```bash
cd app
flutter analyze
dart format lib/ test/
```

## Coding Standards

- Follow the [Effective Dart](https://dart.dev/effective-dart) style guide.
- Use `flutter analyze` with strict rules (configured in `analysis_options.yaml`).
- Write tests for new features and bug fixes.
- Keep functions focused and files under 300 lines where practical.

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add dashboard widget drag-and-drop
fix: resolve MQTT reconnection loop
docs: update ESP32 wiring guide
test: add automation engine unit tests
refactor: extract device provisioning service
chore: update Flutter dependencies
```

## Pull Request Guidelines

- Keep PRs focused on a single change.
- Include tests for new functionality.
- Update documentation if behavior changes.
- Ensure CI passes before requesting review.
- Reference related issues in the PR description.
