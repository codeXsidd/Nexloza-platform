import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';

class AiSuggestionCard extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const AiSuggestionCard({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try asking:', style: theme.textTheme.titleSmall),
        AppSpacing.verticalSm,
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onSuggestionTap(s),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(s, style: theme.textTheme.bodyMedium),
            ),
          ),
        ),
      ],
    );
  }
}
