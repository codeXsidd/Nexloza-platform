import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../profiles/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _timezoneController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _initControllers() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && !_initialized) {
      _nameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
      _bioController.text = profile.bio ?? '';
      _timezoneController.text = profile.timezone;
      _initialized = true;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          timezone: _timezoneController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile updated' : 'Failed to update profile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalMd,
              Text('Failed to load profile: $error'),
              AppSpacing.verticalMd,
              FilledButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          _initControllers();
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(
                              (profile?.displayName ?? 'U')[0].toUpperCase(),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          color: theme.colorScheme.onPrimary,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalLg,
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              AppSpacing.verticalMd,
              AppTextField(
                label: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                enabled: false,
                controller: TextEditingController(text: profile?.email ?? ''),
              ),
              AppSpacing.verticalMd,
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              AppSpacing.verticalMd,
              AppTextField(
                controller: _bioController,
                label: 'Bio',
                prefixIcon: const Icon(Icons.info_outlined),
                maxLines: 3,
              ),
              AppSpacing.verticalMd,
              AppTextField(
                controller: _timezoneController,
                label: 'Timezone',
                prefixIcon: const Icon(Icons.schedule_outlined),
              ),
              AppSpacing.verticalXl,
              AppButton(
                label: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
