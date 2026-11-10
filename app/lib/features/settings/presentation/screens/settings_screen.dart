import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/preferences_service.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setThemeMode(mode);
  }
}

final pushNotificationsProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
      final prefs = ref.watch(preferencesServiceProvider);
      return _BoolPrefNotifier(
        prefs.notificationsEnabled,
        prefs.setNotificationsEnabled,
      );
    });

final emailNotificationsProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
      final prefs = ref.watch(preferencesServiceProvider);
      return _BoolPrefNotifier(
        prefs.emailNotificationsEnabled,
        prefs.setEmailNotificationsEnabled,
      );
    });

class _BoolPrefNotifier extends StateNotifier<bool> {
  final Future<void> Function(bool) _persist;

  _BoolPrefNotifier(super.initial, this._persist);

  void toggle(bool value) {
    state = value;
    _persist(value);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final pushEnabled = ref.watch(pushNotificationsProvider);
    final emailEnabled = ref.watch(emailNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: const Text('Profile'),
            subtitle: const Text('Name, email, avatar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.profile),
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Organizations'),
            subtitle: const Text('Manage teams and access'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.organizations),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outlined),
            title: const Text('Invitations'),
            subtitle: const Text('Pending team invitations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.invitations),
          ),
          const Divider(),

          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(s.first),
            ),
          ),
          const Divider(),

          _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: pushEnabled,
            onChanged: (v) =>
                ref.read(pushNotificationsProvider.notifier).toggle(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Email Notifications'),
            value: emailEnabled,
            onChanged: (v) =>
                ref.read(emailNotificationsProvider.notifier).toggle(v),
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Notification Preferences'),
            subtitle: const Text('Alarm and escalation delivery'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.notificationPreferences),
          ),
          const Divider(),

          _SectionHeader('Developer'),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('API Keys'),
            subtitle: const Text('Manage device API credentials'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.apiKeys),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('Developer Tools'),
            subtitle: const Text('API docs, MQTT info, webhooks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.developerTools),
          ),
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: const Text('Device Studio'),
            subtitle: const Text('Code generator for firmware'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.deviceStudio),
          ),
          const Divider(),

          _SectionHeader('Platform'),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Integrations'),
            subtitle: const Text('Alexa, Google Home, webhooks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.integrations),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Assistant'),
            subtitle: const Text('Chat with NexIoza AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(RouteNames.aiAssistant),
          ),
          const Divider(),

          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('About NexIoza'),
            subtitle: const Text('Version 0.1.0'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'NexIoza',
              applicationVersion: '0.1.0',
            ),
          ),
          const Divider(),
          AppSpacing.verticalSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Log Out',
                  message: 'Are you sure you want to log out?',
                  confirmLabel: 'Log Out',
                  isDestructive: true,
                );
                if (confirmed) {
                  ref.read(authProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          AppSpacing.verticalXl,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
