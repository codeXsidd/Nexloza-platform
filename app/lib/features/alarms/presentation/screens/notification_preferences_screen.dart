import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../../theme/app_spacing.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;

  static const _categories = [
    'device',
    'automation',
    'security',
    'system',
    'alert',
  ];

  static const _categoryLabels = {
    'device': 'Device',
    'automation': 'Automation',
    'security': 'Security',
    'system': 'System',
    'alert': 'Alert',
  };

  static const _categoryIcons = {
    'device': Icons.devices,
    'automation': Icons.auto_awesome,
    'security': Icons.security,
    'system': Icons.settings,
    'alert': Icons.warning_amber,
  };

  final Map<String, _CategoryPref> _prefs = {};
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  String _timezone = 'UTC';
  String _minSeverity = 'info';

  static const _timezones = [
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Paris',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  @override
  void initState() {
    super.initState();
    for (final cat in _categories) {
      _prefs[cat] = _CategoryPref();
    }
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = ref.read(supabaseAuthProvider).currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final response = await supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', userId);

    for (final row in (response as List)) {
      final cat = row['category'] as String?;
      if (cat != null && _prefs.containsKey(cat)) {
        _prefs[cat]!
          ..pushEnabled = row['push_enabled'] as bool? ?? true
          ..emailEnabled = row['email_enabled'] as bool? ?? false
          ..inAppEnabled = row['in_app_enabled'] as bool? ?? true;

        if (row['quiet_hours_enabled'] != null) {
          _quietHoursEnabled = row['quiet_hours_enabled'] as bool;
        }
        if (row['timezone'] != null) {
          _timezone = row['timezone'] as String;
        }
        if (row['min_severity'] != null) {
          _minSeverity = row['min_severity'] as String;
        }
        if (row['quiet_hours_start'] != null) {
          final parts = (row['quiet_hours_start'] as String).split(':');
          if (parts.length >= 2) {
            _quietStart = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 22,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        if (row['quiet_hours_end'] != null) {
          final parts = (row['quiet_hours_end'] as String).split(':');
          if (parts.length >= 2) {
            _quietEnd = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 7,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final supabase = ref.read(supabaseClientProvider);
    final userId = ref.read(supabaseAuthProvider).currentUser?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final quietStartStr =
        '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}:00';
    final quietEndStr =
        '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}:00';

    for (final cat in _categories) {
      final pref = _prefs[cat]!;
      await supabase.from('notification_preferences').upsert(
        {
          'user_id': userId,
          'category': cat,
          'push_enabled': pref.pushEnabled,
          'email_enabled': pref.emailEnabled,
          'in_app_enabled': pref.inAppEnabled,
          'quiet_hours_enabled': _quietHoursEnabled,
          'quiet_hours_start': quietStartStr,
          'quiet_hours_end': quietEndStr,
          'timezone': _timezone,
          'min_severity': _minSeverity,
        },
        onConflict: 'user_id,category',
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            ..._categories.map((cat) => _CategoryCard(
                  category: cat,
                  label: _categoryLabels[cat] ?? cat,
                  icon: _categoryIcons[cat] ?? Icons.notifications,
                  pref: _prefs[cat]!,
                  onChanged: () => setState(() {}),
                )),
            AppSpacing.verticalLg,
            Text('Quiet Hours', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Quiet Hours'),
                      subtitle: const Text(
                          'Suppress non-critical notifications during these hours'),
                      value: _quietHoursEnabled,
                      onChanged: (v) =>
                          setState(() => _quietHoursEnabled = v),
                    ),
                    if (_quietHoursEnabled) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.nightlight),
                        title: const Text('Start'),
                        trailing: TextButton(
                          onPressed: () => _pickTime(true),
                          child: Text(_quietStart.format(context)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny),
                        title: const Text('End'),
                        trailing: TextButton(
                          onPressed: () => _pickTime(false),
                          child: Text(_quietEnd.format(context)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.public),
                        title: const Text('Timezone'),
                        trailing: DropdownButton<String>(
                          value: _timezone,
                          underline: const SizedBox.shrink(),
                          items: _timezones
                              .map((tz) => DropdownMenuItem(
                                    value: tz,
                                    child: Text(
                                      tz.replaceAll('_', ' '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _timezone = v ?? 'UTC'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AppSpacing.verticalLg,
            Text('Minimum Severity', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: DropdownButtonFormField<String>(
                  initialValue: _minSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Only notify for severity at or above',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'info', child: Text('Info (all)')),
                    DropdownMenuItem(
                        value: 'warning', child: Text('Warning+')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical only')),
                  ],
                  onChanged: (v) =>
                      setState(() => _minSeverity = v ?? 'info'),
                ),
              ),
            ),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }
}

class _CategoryPref {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool inAppEnabled = true;
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final String label;
  final IconData icon;
  final _CategoryPref pref;
  final VoidCallback onChanged;

  const _CategoryCard({
    required this.category,
    required this.label,
    required this.icon,
    required this.pref,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(label, style: theme.textTheme.titleSmall),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    title: const Text('In-App'),
                    value: pref.inAppEnabled,
                    onChanged: (v) {
                      pref.inAppEnabled = v ?? true;
                      onChanged();
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    title: const Text('Email'),
                    value: pref.emailEnabled,
                    onChanged: (v) {
                      pref.emailEnabled = v ?? false;
                      onChanged();
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    title: const Text('Push'),
                    value: pref.pushEnabled,
                    onChanged: (v) {
                      pref.pushEnabled = v ?? true;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
