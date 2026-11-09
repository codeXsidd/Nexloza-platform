import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/simulation_profile.dart';
import '../providers/virtual_device_provider.dart';

class CreateVirtualDeviceScreen extends ConsumerStatefulWidget {
  const CreateVirtualDeviceScreen({super.key});

  @override
  ConsumerState<CreateVirtualDeviceScreen> createState() =>
      _CreateVirtualDeviceScreenState();
}

class _CreateVirtualDeviceScreenState
    extends ConsumerState<CreateVirtualDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SimulationProfileType _selectedProfile = SimulationProfileType.smartHome;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryParams = GoRouterState.of(context).uri.queryParameters;
    final projectId = queryParams['projectId'] ?? '';
    final organizationId = queryParams['organizationId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Virtual Device'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isCreating
                  ? null
                  : () => _submit(projectId, organizationId),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g., Living Room Simulator',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What does this virtual device simulate?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Text('Simulation Profile', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose the type of device to simulate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SimulationProfileType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final profile = SimulationProfileType.values[index];
                  final isSelected = profile == _selectedProfile;
                  return _ProfileCard(
                    profile: profile,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedProfile = profile),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _SelectedProfileInfo(profile: _selectedProfile),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(String projectId, String organizationId) async {
    if (!_formKey.currentState!.validate()) return;
    if (projectId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Missing project ID')));
      return;
    }

    setState(() => _isCreating = true);

    final device = await ref
        .read(virtualDeviceControllerProvider)
        .createVirtualDevice(
          projectId: projectId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          profileType: _selectedProfile,
        );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (device != null) {
      ref.invalidate(virtualDevicesProvider(projectId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Virtual device created')));
        context.pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create virtual device')),
      );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final SimulationProfileType profile;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        profile.icon,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedProfileInfo extends StatelessWidget {
  final SimulationProfileType profile;

  const _SelectedProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sim = SimulationProfiles.forType(profile);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(profile.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(profile.displayName, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              profile.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 24),
            Text('Sensors', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sim.sensors
                  .map(
                    (s) => Chip(
                      label: Text(s.name),
                      avatar: Text(s.unit, style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            if (sim.actuators.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Actuators', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: sim.actuators
                    .map(
                      (a) => Chip(
                        label: Text(a.name),
                        avatar: const Icon(Icons.settings_remote, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
