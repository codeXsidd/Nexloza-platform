# Android emulator launch

**Status: unrun.** The existing Windows `emulator-5554` is outside Codex Cloud. APK build and emulator launch are separate checks.

Use the [Windows IoT kit](../LOCAL_DEVELOPMENT_SETUP.md) to verify ADB reports `device`, install the APK, launch `com.nexloza.nexloza/.MainActivity`, and sign in with the disposable user. Record the installation result, activity start result, whether the login screen rendered, and whether sign-in reached the project list. Collect only the kit's sanitized log markers. The PowerShell script passed parser validation in PowerShell 7.5.4 on Linux. Windows execution remains unverified.
