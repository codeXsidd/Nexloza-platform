import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/digital_twin_state.dart';
import '../providers/virtual_device_provider.dart';

class DigitalTwinScreen extends ConsumerWidget {
  final String deviceId;

  const DigitalTwinScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final twinAsync = ref.watch(digitalTwinProvider(deviceId));
    final shortId = deviceId.length > 8
        ? '${deviceId.substring(0, 8)}…'
        : deviceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Twin'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Device: $shortId',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: twinAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text('No twin state available', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        data: (state) {
          if (state == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No twin state available',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start the simulator to initialize twin state',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          return _TwinBody(state: state, deviceId: deviceId, theme: theme);
        },
      ),
    );
  }
}

class _TwinBody extends ConsumerWidget {
  final DigitalTwinState state;
  final String deviceId;
  final ThemeData theme;

  const _TwinBody({
    required this.state,
    required this.deviceId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SyncStatusCard(state: state, theme: theme),
          const SizedBox(height: 16),
          _StateComparisonCard(state: state, theme: theme),
          const SizedBox(height: 16),
          _DesiredStateCard(state: state, deviceId: deviceId, theme: theme),
          const SizedBox(height: 16),
          _ReportedStateCard(state: state, theme: theme),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final DigitalTwinState state;
  final ThemeData theme;

  const _SyncStatusCard({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (state.syncStatus) {
      TwinSyncStatus.synced => (Icons.check_circle, Colors.green, 'In Sync'),
      TwinSyncStatus.pending => (Icons.sync, Colors.orange, 'Synchronizing'),
      TwinSyncStatus.failed => (Icons.error, Colors.red, 'Sync Failed'),
      TwinSyncStatus.stale => (Icons.warning, Colors.amber, 'Stale Data'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VersionChip(
                  label: 'Reported',
                  version: state.reportedVersion,
                  theme: theme,
                ),
                const SizedBox(width: 16),
                _VersionChip(
                  label: 'Desired',
                  version: state.desiredVersion,
                  theme: theme,
                ),
              ],
            ),
            if (state.lastSyncAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: ${_formatTime(state.lastSyncAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final int version;
  final ThemeData theme;

  const _VersionChip({
    required this.label,
    required this.version,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'v$version',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateComparisonCard extends StatelessWidget {
  final DigitalTwinState state;
  final ThemeData theme;

  const _StateComparisonCard({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final allKeys = {
      ...state.desiredState.keys,
      ...state.reportedState.keys,
    }.toList()..sort();

    if (allKeys.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No state attributes yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State Comparison', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${state.getMismatches().length} mismatched attributes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.getMismatches().isEmpty
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Attribute',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Desired',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Reported',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            for (final key in allKeys)
              _ComparisonRow(
                attributeKey: key,
                desired: state.desiredState[key],
                reported: state.reportedState[key],
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String attributeKey;
  final dynamic desired;
  final dynamic reported;
  final ThemeData theme;

  const _ComparisonRow({
    required this.attributeKey,
    required this.desired,
    required this.reported,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final matches = desired == reported;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: matches
            ? null
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(attributeKey, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatValue(desired),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatValue(reported),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Icon(
              matches ? Icons.check : Icons.close,
              size: 16,
              color: matches ? Colors.green : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is double) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }
    return value.toString();
  }
}

class _DesiredStateCard extends ConsumerWidget {
  final DigitalTwinState state;
  final String deviceId;
  final ThemeData theme;

  const _DesiredStateCard({
    required this.state,
    required this.deviceId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = state.desiredState.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Desired State', style: theme.textTheme.titleMedium),
              ],
            ),
            if (state.desiredAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last updated: ${_formatTimestamp(state.desiredAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const Divider(),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No desired state set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              for (final entry in entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: Text(
                    _formatValue(entry.value),
                    style: theme.textTheme.titleSmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () =>
                        _showEditDialog(context, ref, entry.key, entry.value),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String key,
    dynamic currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue.toString());
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Value',
            hintText: currentValue.toString(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    dynamic newValue = result;
    final numericValue = double.tryParse(result);
    if (numericValue != null) newValue = numericValue;

    ref
        .read(virtualDeviceControllerProvider)
        .updateDesiredState(
          deviceId: deviceId,
          attributes: {key: newValue},
          expectedVersion: state.desiredVersion,
        );
    ref.invalidate(digitalTwinProvider(deviceId));
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is double) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }
    return value.toString();
  }
}

class _ReportedStateCard extends StatelessWidget {
  final DigitalTwinState state;
  final ThemeData theme;

  const _ReportedStateCard({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final entries = state.reportedState.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text('Reported State', style: theme.textTheme.titleMedium),
              ],
            ),
            if (state.reportedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last reported: ${_formatTimestamp(state.reportedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const Divider(),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No reported state yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              for (final entry in entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: Text(
                    _formatValue(entry.value),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reported by the device simulator — cannot be edited directly',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is double) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }
    return value.toString();
  }
}
