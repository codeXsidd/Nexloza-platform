import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

// --- Shared helper ---
Widget _controlCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data, {
  required Widget child,
}) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          child,
          const Spacer(),
        ],
      ),
    ),
  );
}

// 1. Switch
Widget buildSwitchControl(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _controlCard(context, widget, data, child: _SwitchBody(data: data));
}

class _SwitchBody extends StatefulWidget {
  final WidgetDataState data;
  const _SwitchBody({required this.data});
  @override
  State<_SwitchBody> createState() => _SwitchBodyState();
}

class _SwitchBodyState extends State<_SwitchBody> {
  late bool _value;
  @override
  void initState() {
    super.initState();
    _value = widget.data.boolValue;
  }

  @override
  void didUpdateWidget(_SwitchBody old) {
    super.didUpdateWidget(old);
    _value = widget.data.boolValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _value ? 'ON' : 'OFF',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: _value
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        Switch(value: _value, onChanged: (v) => setState(() => _value = v)),
      ],
    );
  }
}

// 2. Button
Widget buildButton(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final label = widget.config['label'] as String? ?? 'Execute';
  return _controlCard(
    context,
    widget,
    data,
    child: Center(
      child: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.play_arrow, size: 18),
        label: Text(label),
      ),
    ),
  );
}

// 3. Slider
Widget buildSlider(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  return _controlCard(
    context,
    w,
    data,
    child: _SliderBody(widget: w, data: data),
  );
}

class _SliderBody extends StatefulWidget {
  final DashboardWidget widget;
  final WidgetDataState data;
  const _SliderBody({required this.widget, required this.data});
  @override
  State<_SliderBody> createState() => _SliderBodyState();
}

class _SliderBodyState extends State<_SliderBody> {
  late double _value;
  @override
  void initState() {
    super.initState();
    _value = widget.data.numericValue.clamp(
      widget.widget.rangeMin,
      widget.widget.rangeMax,
    );
  }

  @override
  void didUpdateWidget(_SliderBody old) {
    super.didUpdateWidget(old);
    _value = widget.data.numericValue.clamp(
      widget.widget.rangeMin,
      widget.widget.rangeMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_value.toStringAsFixed(widget.widget.decimals)}${widget.widget.unit}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: _value,
          min: widget.widget.rangeMin,
          max: widget.widget.rangeMax,
          onChanged: (v) => setState(() => _value = v),
        ),
      ],
    );
  }
}

// 4. Numeric Input
Widget buildNumericInput(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  return _controlCard(
    context,
    w,
    data,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: () {},
          icon: const Icon(Icons.remove, size: 18),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${data.numericValue.toStringAsFixed(w.decimals)}${w.unit}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton.filled(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}

// 5. Dropdown
Widget buildDropdown(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  final options =
      (w.config['options'] as List?)?.cast<String>() ??
      ['Option 1', 'Option 2', 'Option 3'];
  return _controlCard(
    context,
    w,
    data,
    child: Center(
      child: DropdownButton<String>(
        value: data.hasData ? data.stringValue : null,
        hint: const Text('Select...'),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (_) {},
      ),
    ),
  );
}

// 6. Fan Speed
Widget buildFanSpeed(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final speed = data.numericValue.toInt().clamp(0, 5);
  return _controlCard(
    context,
    w,
    data,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.air,
          size: 32,
          color: speed > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        const SizedBox(height: 4),
        Text(
          'Speed $speed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 20,
                height: 6,
                decoration: BoxDecoration(
                  color: i < speed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// 7. Relay Control
Widget buildRelayControl(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  return _controlCard(context, w, data, child: _RelayBody(data: data));
}

class _RelayBody extends StatefulWidget {
  final WidgetDataState data;
  const _RelayBody({required this.data});
  @override
  State<_RelayBody> createState() => _RelayBodyState();
}

class _RelayBodyState extends State<_RelayBody> {
  late bool _on;
  @override
  void initState() {
    super.initState();
    _on = widget.data.boolValue;
  }

  @override
  void didUpdateWidget(_RelayBody old) {
    super.didUpdateWidget(old);
    _on = widget.data.boolValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.power,
          size: 36,
          color: _on ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        const SizedBox(height: 4),
        Text(
          _on ? 'CLOSED' : 'OPEN',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _on ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.tonal(
          onPressed: () => setState(() => _on = !_on),
          child: Text(_on ? 'Turn Off' : 'Turn On'),
        ),
      ],
    );
  }
}

// 8. Valve Control
Widget buildValveControl(
  BuildContext context,
  DashboardWidget w,
  WidgetDataState data,
) {
  return _controlCard(context, w, data, child: _ValveBody(data: data));
}

class _ValveBody extends StatefulWidget {
  final WidgetDataState data;
  const _ValveBody({required this.data});
  @override
  State<_ValveBody> createState() => _ValveBodyState();
}

class _ValveBodyState extends State<_ValveBody> {
  late bool _open;
  @override
  void initState() {
    super.initState();
    _open = widget.data.boolValue;
  }

  @override
  void didUpdateWidget(_ValveBody old) {
    super.didUpdateWidget(old);
    _open = widget.data.boolValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.water_drop,
          size: 36,
          color: _open ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        const SizedBox(height: 4),
        Text(
          _open ? 'OPEN' : 'CLOSED',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _open
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.tonal(
          onPressed: () => setState(() => _open = !_open),
          child: Text(_open ? 'Close Valve' : 'Open Valve'),
        ),
      ],
    );
  }
}
