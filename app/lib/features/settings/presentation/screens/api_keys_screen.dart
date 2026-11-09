import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../devices/domain/entities/device_credential_entity.dart';

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('API Keys')),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (devices) {
          if (devices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.vpn_key_outlined,
              title: 'No Devices',
              subtitle:
                  'API keys are generated per device. Add a device first.',
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final credentialsAsync = ref.watch(
                deviceCredentialsProvider(device.id),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.memory,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              device.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final cred = await ref
                                  .read(devicesProvider.notifier)
                                  .provisionCredentials(device.id);
                              if (cred != null && context.mounted) {
                                _showCredentialDialog(context, cred);
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Generate'),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSm,
                      credentialsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Failed to load credentials'),
                        data: (credentials) {
                          if (credentials.isEmpty) {
                            return Text(
                              'No API keys yet',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            );
                          }
                          return Column(
                            children: credentials.map((c) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  c.isActive ? Icons.key : Icons.key_off,
                                  size: 20,
                                  color: c.isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                title: Text(
                                  'Key: ${c.apiKey.substring(0, 8)}...',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
                                ),
                                subtitle: Text(
                                  c.isActive ? 'Active' : 'Revoked',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: c.apiKey),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('API key copied'),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCredentialDialog(BuildContext context, ProvisionedCredential cred) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save this secret now — it cannot be retrieved again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalMd,
            _KeyRow(label: 'API Key', value: cred.apiKey),
            AppSpacing.verticalSm,
            _KeyRow(label: 'API Secret', value: cred.apiSecret),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$label copied')));
              },
            ),
          ],
        ),
      ],
    );
  }
}
