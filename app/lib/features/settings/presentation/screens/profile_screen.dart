import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController.text = user?.userMetadata?['full_name'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (auth.user?.userMetadata?['full_name'] as String? ?? 'U')[0].toUpperCase(),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
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
            controller: TextEditingController(text: auth.user?.email ?? ''),
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
          AppSpacing.verticalXl,
          AppButton(
            label: 'Save Changes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile update requires Supabase connection')),
              );
            },
          ),
        ],
      ),
    );
  }
}
