import 'package:flutter/widgets.dart';

enum ScreenSize { compactMobile, mobile, tablet, desktop, wideDesktop }

abstract final class AppBreakpoints {
  static const double compactMobile = 360;
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1440;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  static ScreenSize fromWidth(double width) {
    if (width < mobile) return ScreenSize.compactMobile;
    if (width < tablet) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    if (width < wideDesktop) return ScreenSize.desktop;
    return ScreenSize.wideDesktop;
  }

  static bool isMobile(BuildContext context) {
    final size = of(context);
    return size == ScreenSize.compactMobile || size == ScreenSize.mobile;
  }

  static bool isTablet(BuildContext context) =>
      of(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) {
    final size = of(context);
    return size == ScreenSize.desktop || size == ScreenSize.wideDesktop;
  }

  static bool isDesktopOrTablet(BuildContext context) {
    final size = of(context);
    return size == ScreenSize.tablet ||
        size == ScreenSize.desktop ||
        size == ScreenSize.wideDesktop;
  }

  static int gridColumns(BuildContext context) {
    return switch (of(context)) {
      ScreenSize.compactMobile => 1,
      ScreenSize.mobile => 2,
      ScreenSize.tablet => 3,
      ScreenSize.desktop => 4,
      ScreenSize.wideDesktop => 4,
    };
  }

  static double contentMaxWidth(BuildContext context) {
    return switch (of(context)) {
      ScreenSize.compactMobile => double.infinity,
      ScreenSize.mobile => double.infinity,
      ScreenSize.tablet => double.infinity,
      ScreenSize.desktop => 1200,
      ScreenSize.wideDesktop => 1400,
    };
  }

  static EdgeInsets screenPadding(BuildContext context) {
    return switch (of(context)) {
      ScreenSize.compactMobile => const EdgeInsets.all(12),
      ScreenSize.mobile => const EdgeInsets.all(16),
      ScreenSize.tablet => const EdgeInsets.all(20),
      ScreenSize.desktop => const EdgeInsets.all(24),
      ScreenSize.wideDesktop => const EdgeInsets.all(32),
    };
  }
}
