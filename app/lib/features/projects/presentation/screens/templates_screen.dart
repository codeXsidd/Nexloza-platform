import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/features/organizations/presentation/providers/organization_provider.dart';
import 'package:nexioza/features/projects/presentation/providers/project_provider.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Project Templates')),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const NexiozaEmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: 'No templates',
              message: 'Project templates will appear here when available.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final tmpl = templates[index];
              final color = Color(
                int.parse(tmpl.color.substring(1), radix: 16) + 0xFF000000,
              );
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _createFromTemplate(context, ref, tmpl),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.dashboard_customize_rounded,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          tmpl.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (tmpl.description != null &&
                            tmpl.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tmpl.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(templatesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createFromTemplate(
    BuildContext context,
    WidgetRef ref,
    Project template,
  ) {
    final nameController = TextEditingController(text: template.name);
    final orgs = ref.read(organizationsProvider).valueOrNull ?? [];
    String? selectedOrgId = orgs.isNotEmpty ? orgs.first.id : null;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create from Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (orgs.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedOrgId,
                  decoration: const InputDecoration(
                    labelText: 'Organization',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                  items: orgs
                      .map(
                        (o) =>
                            DropdownMenuItem(value: o.id, child: Text(o.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedOrgId = v),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedOrgId == null ||
                    nameController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(projectRepositoryProvider)
                      .createProjectFromTemplate(
                        organizationId: selectedOrgId!,
                        templateId: template.id,
                        name: nameController.text.trim(),
                      );
                  ref.invalidate(projectsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project created from template'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.go('/projects');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
