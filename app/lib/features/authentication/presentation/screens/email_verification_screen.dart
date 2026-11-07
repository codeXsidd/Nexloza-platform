import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread, size: 80, color: theme.colorScheme.primary),
                AppSpacing.verticalLg,
                Text('Check Your Email', style: theme.textTheme.headlineMedium),
                AppSpacing.verticalSm,
                Text(
                  'We\'ve sent a verification link to your email address. Please verify to continue.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalXl,
                AppButton(
                  label: 'Open Email App',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
