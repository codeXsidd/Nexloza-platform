import 'package:flutter/material.dart';

class NexiozaButton extends StatelessWidget {
  const NexiozaButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
  }) : _variant = _ButtonVariant.primary;

  const NexiozaButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
  }) : _variant = _ButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _variant == _ButtonVariant.primary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    return SizedBox(
      height: 48,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120),
        child: switch (_variant) {
          _ButtonVariant.primary => FilledButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
          _ButtonVariant.secondary => OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
        },
      ),
    );
  }
}

enum _ButtonVariant { primary, secondary }
