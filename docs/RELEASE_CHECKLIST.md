# Release Checklist

> Pre-release verification for NexIoza.

## Pre-release

- [ ] All tests pass (`flutter test`)
- [ ] Static analysis clean (`flutter analyze`)
- [ ] No secrets committed
- [ ] CHANGELOG.md updated
- [ ] Version bumped in pubspec.yaml
- [ ] Documentation up to date

## Build

- [ ] Debug APK builds successfully
- [ ] Release APK builds successfully
- [ ] Release AAB builds successfully
- [ ] Web build compiles (if applicable)

## Testing

- [ ] Smoke test on physical Android device
- [ ] Theme switching (light/dark/system) works
- [ ] Navigation between all sections works
- [ ] Offline behavior is acceptable

## Documentation

- [ ] README reflects current state
- [ ] All setup guides are accurate
- [ ] API reference matches implementation

## Publishing

- [ ] Git tag created
- [ ] GitHub Release created with artifacts
- [ ] Release notes written
