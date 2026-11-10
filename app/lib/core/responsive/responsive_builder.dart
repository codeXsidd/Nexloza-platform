import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = AppBreakpoints.fromWidth(
          MediaQuery.sizeOf(context).width,
        );
        return builder(context, screenSize);
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = AppBreakpoints.of(context);
    return switch (screenSize) {
      ScreenSize.desktop ||
      ScreenSize.wideDesktop => desktop ?? tablet ?? mobile,
      ScreenSize.tablet => tablet ?? mobile,
      _ => mobile,
    };
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? AppBreakpoints.gridColumns(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (cols - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth.clamp(0, constraints.maxWidth),
                child: child,
              ),
          ],
        );
      },
    );
  }
}
