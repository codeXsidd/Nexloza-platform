import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/integration_entity.dart';
import '../providers/integration_provider.dart';

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  static IconData _iconFor(IntegrationType type) => switch (type) {
    IntegrationType.webhook => Icons.webhook,
    IntegrationType.mqtt => Icons.router,
    IntegrationType.httpApi => Icons.api,
    IntegrationType.slack => Icons.chat,
    IntegrationType.email => Icons.email,
    IntegrationType.telegram => Icons.send,
    IntegrationType.custom => Icons.extension,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrationsAsync = ref.watch(integrationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: integrationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load integrations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(integrationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (integrations) {
          if (integrations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.extension_outlined,
              title: 'No Integrations',
              subtitle: 'Connect external services like webhooks, Slack, or MQTT bridges.',
              actionLabel: 'Add Integration',
              onAction: () => _showCreateSheet(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(integrationsProvider),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: integrations.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                final integration = integrations[index];
                return _IntegrationCard(
                  integration: integration,
                  icon: _iconFor(integration.integrationType),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Integration'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    IntegrationType selectedType = IntegrationType.webhook;
    String? selectedProjectId;
    final projectsAsync = ref.read(projectsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Integration', style: theme.textTheme.titleLarge),
                AppSpacing.verticalMd,
                projectsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load projects'),
                  data: (projects) {
                    if (projects.isEmpty) {
                      return const Text('Create a project first.');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: projects
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                          v == null ? 'Please select a project' : null,
                      onChanged: (v) =>
                          setSheetState(() => selectedProjectId = v),
                    );
                  },
                ),
                AppSpacing.verticalMd,
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Integration Name',
                    prefixIcon: Icon(Icons.label_outlined),
                  ),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                AppSpacing.verticalMd,
                DropdownButtonFormField<IntegrationType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.extension_outlined),
                  ),
                  items: IntegrationType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(
                    () => selectedType = v ?? IntegrationType.webhook,
                  ),
                ),
                AppSpacing.verticalLg,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedProjectId == null) return;
                      Navigator.pop(ctx);
                      await ref
                          .read(integrationsProvider.notifier)
                          .createIntegration(
                            projectId: selectedProjectId!,
                            name: nameController.text.trim(),
                            integrationType: selectedType,
                          );
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntegrationCard extends ConsumerWidget {
  final Integration integration;
  final IconData icon;

  const _IntegrationCard({required this.integration, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: integration.isEnabled
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: integration.isEnabled
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.outline,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(integration.name, style: theme.textTheme.titleMedium),
                  Text(
                    integration.integrationType.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: integration.isEnabled,
              onChanged: (v) => ref
                  .read(integrationsProvider.notifier)
                  .toggleIntegration(integration.id, v),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              onPressed: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Delete Integration',
                  message: 'Delete "${integration.name}"?',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed) {
                  ref
                      .read(integrationsProvider.notifier)
                      .deleteIntegration(integration.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
