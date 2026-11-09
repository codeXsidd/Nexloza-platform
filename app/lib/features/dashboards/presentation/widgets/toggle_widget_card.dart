import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class ToggleWidgetCard extends StatefulWidget {
  final DashboardWidget widget;

  const ToggleWidgetCard({super.key, required this.widget});

  @override
  State<ToggleWidgetCard> createState() => _ToggleWidgetCardState();
}

class _ToggleWidgetCardState extends State<ToggleWidgetCard> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.widget.config['value'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceName = widget.widget.config['device_name'] as String? ?? '';

    return Card(
      color: _isOn ? theme.colorScheme.primaryContainer.withAlpha(80) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => setState(() => _isOn = !_isOn),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.widget.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Switch(
                    value: _isOn,
                    onChanged: (v) => setState(() => _isOn = v),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                _isOn ? Icons.power : Icons.power_off,
                size: 40,
                color: _isOn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              AppSpacing.verticalXs,
              Text(
                _isOn ? 'ON' : 'OFF',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isOn
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              if (deviceName.isNotEmpty)
                Text(
                  deviceName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
