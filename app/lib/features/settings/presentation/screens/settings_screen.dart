import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/shared/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final displayName =
        user?.userMetadata?['display_name'] as String? ?? 'NexIoza User';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(displayName),
            subtitle: Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile editing coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              return RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                  }
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('System default'),
                      subtitle: Text('Match device settings'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'About',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            trailing: Text(
              '0.1.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'NexIoza',
                applicationVersion: '0.1.0',
                applicationLegalese:
                    'One Platform. Unlimited IoT Possibilities.',
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content:
                        const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/auth/login');
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
