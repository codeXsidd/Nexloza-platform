import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/organization_provider.dart';

class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Organizations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/organizations/create'),
        child: const Icon(Icons.add),
      ),
      body: orgsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (orgs) {
          if (orgs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.business_outlined,
              title: 'No Organizations',
              subtitle: 'Create an organization to collaborate with your team',
              actionLabel: 'Create Organization',
              onAction: () => context.push('/organizations/create'),
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              final org = orgs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      org.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(org.name),
                  subtitle: org.description != null
                      ? Text(
                          org.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/organizations/${org.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
