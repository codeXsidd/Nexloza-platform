import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/theme/app_colors.dart';
import 'package:nexloza/theme/app_theme.dart';
import 'package:nexloza/theme/app_spacing.dart';
import 'package:nexloza/core/responsive/breakpoints.dart';
import 'package:nexloza/core/responsive/responsive_builder.dart';
import 'package:nexloza/core/design_system/design_system.dart';
import 'package:nexloza/routing/route_names.dart';
import 'package:nexloza/features/dashboards/domain/entities/widget_type.dart';
import 'package:nexloza/features/dashboards/presentation/widgets/renderers/widget_registrations.dart';

void main() {
  // ──────────────────────────────────────────────────────────
  // 1. Design System — Color palette
  // ──────────────────────────────────────────────────────────

  group('AppColors — brand palette', () {
    test('primary is indigo #6366F1', () {
      expect(AppColors.primary, const Color(0xFF6366F1));
    });
    test('primaryDark is #4F46E5', () {
      expect(AppColors.primaryDark, const Color(0xFF4F46E5));
    });
    test('primaryLight is #818CF8', () {
      expect(AppColors.primaryLight, const Color(0xFF818CF8));
    });
    test('secondary is #0EA5E9', () {
      expect(AppColors.secondary, const Color(0xFF0EA5E9));
    });
    test('tertiary is #8B5CF6', () {
      expect(AppColors.tertiary, const Color(0xFF8B5CF6));
    });
  });

  group('AppColors — semantic colors', () {
    test('success is #22C55E', () {
      expect(AppColors.success, const Color(0xFF22C55E));
    });
    test('warning is #F59E0B', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });
    test('error is #EF4444', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });
    test('info is #3B82F6', () {
      expect(AppColors.info, const Color(0xFF3B82F6));
    });
    test('online is green (matches success)', () {
      expect(AppColors.online, const Color(0xFF22C55E));
    });
    test('offline is gray', () {
      expect(AppColors.offline, const Color(0xFF9CA3AF));
    });
  });

  group('AppColors — alarm severity colors', () {
    test('alarmCritical exists and is red', () {
      expect(AppColors.alarmCritical, isNotNull);
      expect(AppColors.alarmCritical, const Color(0xFFEF4444));
    });
    test('alarmHigh exists', () {
      expect(AppColors.alarmHigh, isNotNull);
    });
    test('alarmMedium exists', () {
      expect(AppColors.alarmMedium, isNotNull);
    });
    test('alarmWarning exists', () {
      expect(AppColors.alarmWarning, isNotNull);
    });
    test('alarmInfo exists', () {
      expect(AppColors.alarmInfo, isNotNull);
    });
  });

  group('AppColors — light surface tokens', () {
    test('backgroundLight exists', () {
      expect(AppColors.backgroundLight, isNotNull);
    });
    test('surfaceLight exists', () {
      expect(AppColors.surfaceLight, isNotNull);
    });
    test('surfaceElevatedLight exists', () {
      expect(AppColors.surfaceElevatedLight, isNotNull);
    });
    test('cardLight exists', () {
      expect(AppColors.cardLight, isNotNull);
    });
    test('dividerLight exists', () {
      expect(AppColors.dividerLight, isNotNull);
    });
    test('textPrimaryLight exists', () {
      expect(AppColors.textPrimaryLight, isNotNull);
    });
    test('textSecondaryLight exists', () {
      expect(AppColors.textSecondaryLight, isNotNull);
    });
    test('disabledLight exists', () {
      expect(AppColors.disabledLight, isNotNull);
    });
  });

  group('AppColors — dark surface tokens', () {
    test('backgroundDark exists', () {
      expect(AppColors.backgroundDark, isNotNull);
    });
    test('surfaceDark exists', () {
      expect(AppColors.surfaceDark, isNotNull);
    });
    test('surfaceElevatedDark exists', () {
      expect(AppColors.surfaceElevatedDark, isNotNull);
    });
    test('cardDark exists', () {
      expect(AppColors.cardDark, isNotNull);
    });
    test('dividerDark exists', () {
      expect(AppColors.dividerDark, isNotNull);
    });
    test('textPrimaryDark exists', () {
      expect(AppColors.textPrimaryDark, isNotNull);
    });
    test('textSecondaryDark exists', () {
      expect(AppColors.textSecondaryDark, isNotNull);
    });
    test('disabledDark exists', () {
      expect(AppColors.disabledDark, isNotNull);
    });
  });

  group('AppColors — light/dark surfaces differ', () {
    test('background colors differ', () {
      expect(AppColors.backgroundLight, isNot(AppColors.backgroundDark));
    });
    test('surface colors differ', () {
      expect(AppColors.surfaceLight, isNot(AppColors.surfaceDark));
    });
    test('card colors differ', () {
      expect(AppColors.cardLight, isNot(AppColors.cardDark));
    });
    test('divider colors differ', () {
      expect(AppColors.dividerLight, isNot(AppColors.dividerDark));
    });
    test('text primary colors differ', () {
      expect(AppColors.textPrimaryLight, isNot(AppColors.textPrimaryDark));
    });
  });

  // ──────────────────────────────────────────────────────────
  // 2. Spacing
  // ──────────────────────────────────────────────────────────

  group('AppSpacing — 8-point grid', () {
    test('xs is 4', () => expect(AppSpacing.xs, 4));
    test('sm is 8', () => expect(AppSpacing.sm, 8));
    test('md is 16', () => expect(AppSpacing.md, 16));
    test('lg is 24', () => expect(AppSpacing.lg, 24));
    test('xl is 32', () => expect(AppSpacing.xl, 32));
    test('xxl is 48', () => expect(AppSpacing.xxl, 48));
    test('cardRadius is 12', () => expect(AppSpacing.cardRadius, 12));
    test('buttonRadius is 12', () => expect(AppSpacing.buttonRadius, 12));
    test('inputRadius is 12', () => expect(AppSpacing.inputRadius, 12));
  });

  // ──────────────────────────────────────────────────────────
  // 3. Themes
  // ──────────────────────────────────────────────────────────

  group('AppTheme — light', () {
    final light = AppTheme.light;

    test('exists', () => expect(light, isNotNull));
    test('brightness is light', () {
      expect(light.brightness, Brightness.light);
    });
    test('useMaterial3 is true', () {
      expect(light.useMaterial3, isTrue);
    });
    test('primary color matches AppColors.primary', () {
      expect(light.colorScheme.primary, AppColors.primary);
    });
    test('scaffold background is backgroundLight', () {
      expect(light.scaffoldBackgroundColor, AppColors.backgroundLight);
    });
    test('card theme has correct radius', () {
      final shape = light.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppSpacing.cardRadius));
    });
  });

  group('AppTheme — dark', () {
    final dark = AppTheme.dark;

    test('exists', () => expect(dark, isNotNull));
    test('brightness is dark', () {
      expect(dark.brightness, Brightness.dark);
    });
    test('useMaterial3 is true', () {
      expect(dark.useMaterial3, isTrue);
    });
    test('scaffold background is backgroundDark', () {
      expect(dark.scaffoldBackgroundColor, AppColors.backgroundDark);
    });
    test('primary is primaryLight for dark theme contrast', () {
      expect(dark.colorScheme.primary, AppColors.primaryLight);
    });
  });

  group('AppTheme — light vs dark differ', () {
    test('scaffold backgrounds differ', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        isNot(AppTheme.dark.scaffoldBackgroundColor),
      );
    });
    test('brightness values differ', () {
      expect(AppTheme.light.brightness, isNot(AppTheme.dark.brightness));
    });
  });

  // ──────────────────────────────────────────────────────────
  // 4. Responsive breakpoints
  // ──────────────────────────────────────────────────────────

  group('AppBreakpoints — fromWidth exact boundaries', () {
    test('599 → compactMobile', () {
      expect(AppBreakpoints.fromWidth(599), ScreenSize.compactMobile);
    });
    test('600 → mobile', () {
      expect(AppBreakpoints.fromWidth(600), ScreenSize.mobile);
    });
    test('899 → mobile', () {
      expect(AppBreakpoints.fromWidth(899), ScreenSize.mobile);
    });
    test('900 → tablet', () {
      expect(AppBreakpoints.fromWidth(900), ScreenSize.tablet);
    });
    test('1199 → tablet', () {
      expect(AppBreakpoints.fromWidth(1199), ScreenSize.tablet);
    });
    test('1200 → desktop', () {
      expect(AppBreakpoints.fromWidth(1200), ScreenSize.desktop);
    });
    test('1439 → desktop', () {
      expect(AppBreakpoints.fromWidth(1439), ScreenSize.desktop);
    });
    test('1440 → wideDesktop', () {
      expect(AppBreakpoints.fromWidth(1440), ScreenSize.wideDesktop);
    });
  });

  group('AppBreakpoints — representative widths', () {
    test('350 → compactMobile', () {
      expect(AppBreakpoints.fromWidth(350), ScreenSize.compactMobile);
    });
    test('500 → compactMobile', () {
      expect(AppBreakpoints.fromWidth(500), ScreenSize.compactMobile);
    });
    test('650 → mobile', () {
      expect(AppBreakpoints.fromWidth(650), ScreenSize.mobile);
    });
    test('950 → tablet', () {
      expect(AppBreakpoints.fromWidth(950), ScreenSize.tablet);
    });
    test('1300 → desktop', () {
      expect(AppBreakpoints.fromWidth(1300), ScreenSize.desktop);
    });
    test('1500 → wideDesktop', () {
      expect(AppBreakpoints.fromWidth(1500), ScreenSize.wideDesktop);
    });
    test('1920 → wideDesktop', () {
      expect(AppBreakpoints.fromWidth(1920), ScreenSize.wideDesktop);
    });
  });

  group('AppBreakpoints — constant values', () {
    test('compactMobile threshold is 360', () {
      expect(AppBreakpoints.compactMobile, 360);
    });
    test('mobile threshold is 600', () {
      expect(AppBreakpoints.mobile, 600);
    });
    test('tablet threshold is 900', () {
      expect(AppBreakpoints.tablet, 900);
    });
    test('desktop threshold is 1200', () {
      expect(AppBreakpoints.desktop, 1200);
    });
    test('wideDesktop threshold is 1440', () {
      expect(AppBreakpoints.wideDesktop, 1440);
    });
  });

  // ──────────────────────────────────────────────────────────
  // 5. Route names
  // ──────────────────────────────────────────────────────────

  group('RouteNames — shell branch routes exist', () {
    test('home', () => expect(RouteNames.home, 'home'));
    test('devices', () => expect(RouteNames.devices, 'devices'));
    test('automations', () => expect(RouteNames.automations, 'automations'));
    test('analytics', () => expect(RouteNames.analytics, 'analytics'));
    test('settings', () => expect(RouteNames.settings, 'settings'));
  });

  group('RouteNames — Phase 10 new routes', () {
    test('deviceTemplates', () {
      expect(RouteNames.deviceTemplates, 'deviceTemplates');
    });
    test('firmware', () {
      expect(RouteNames.firmware, 'firmware');
    });
    test('developerTools', () {
      expect(RouteNames.developerTools, 'developerTools');
    });
  });

  group('RouteNames — existing routes preserved', () {
    test('projects', () => expect(RouteNames.projects, 'projects'));
    test('organizations', () {
      expect(RouteNames.organizations, 'organizations');
    });
    test('dashboards', () => expect(RouteNames.dashboards, 'dashboards'));
    test('rules', () => expect(RouteNames.rules, 'rules'));
    test('alarms', () => expect(RouteNames.alarms, 'alarms'));
    test('integrations', () {
      expect(RouteNames.integrations, 'integrations');
    });
    test('virtualDevices', () {
      expect(RouteNames.virtualDevices, 'virtualDevices');
    });
    test('scenes', () => expect(RouteNames.scenes, 'scenes'));
    test('notifications', () {
      expect(RouteNames.notifications, 'notifications');
    });
    test('aiAssistant', () {
      expect(RouteNames.aiAssistant, 'aiAssistant');
    });
  });

  // ──────────────────────────────────────────────────────────
  // 6. Design components render
  // ──────────────────────────────────────────────────────────

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  group('NexStatCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexStatCard(label: 'Devices', value: '42', icon: Icons.devices),
        ),
      );
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexStatCard(
            label: 'Online',
            value: '10',
            icon: Icons.wifi,
            subtitle: '5 offline',
          ),
        ),
      );
      expect(find.text('5 offline'), findsOneWidget);
    });

    testWidgets('shows chevron when onTap provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          NexStatCard(
            label: 'Tap Me',
            value: '1',
            icon: Icons.touch_app,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('NexDeviceCard', () {
    testWidgets('renders device name', (tester) async {
      await tester.pumpWidget(
        wrap(const NexDeviceCard(name: 'ESP32-Living-Room')),
      );
      expect(find.text('ESP32-Living-Room'), findsOneWidget);
    });

    testWidgets('shows Virtual badge for virtual devices', (tester) async {
      await tester.pumpWidget(
        wrap(const NexDeviceCard(name: 'Sim-1', isVirtual: true)),
      );
      expect(find.text('Virtual'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(const NexDeviceCard(name: 'D1', subtitle: 'Temperature sensor')),
      );
      expect(find.text('Temperature sensor'), findsOneWidget);
    });
  });

  group('NexDeviceGridCard', () {
    testWidgets('renders name and online status', (tester) async {
      await tester.pumpWidget(
        wrap(const NexDeviceGridCard(name: 'Sensor-A', isOnline: true)),
      );
      expect(find.text('Sensor-A'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('shows Offline label when not online', (tester) async {
      await tester.pumpWidget(
        wrap(const NexDeviceGridCard(name: 'Sensor-B', isOnline: false)),
      );
      expect(find.text('Offline'), findsOneWidget);
    });
  });

  group('NexAlarmCard', () {
    testWidgets('renders title and severity badge', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexAlarmCard(
            title: 'High temperature',
            severity: AlarmSeverityLevel.critical,
          ),
        ),
      );
      expect(find.text('High temperature'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexAlarmCard(
            title: 'Overload',
            severity: AlarmSeverityLevel.high,
            description: 'Motor exceeded rated current',
          ),
        ),
      );
      expect(find.text('Motor exceeded rated current'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders device name when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexAlarmCard(
            title: 'Low battery',
            severity: AlarmSeverityLevel.warning,
            deviceName: 'Sensor-X',
          ),
        ),
      );
      expect(find.text('Sensor-X'), findsOneWidget);
    });

    testWidgets('shows acknowledge button when not acknowledged', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          NexAlarmCard(
            title: 'Alert',
            severity: AlarmSeverityLevel.medium,
            onAcknowledge: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    test('all severity levels produce distinct labels', () {
      final labels = AlarmSeverityLevel.values.map((s) => s.name).toSet();
      expect(labels.length, AlarmSeverityLevel.values.length);
    });
  });

  group('NexSectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(wrap(const NexSectionHeader(title: 'Devices')));
      expect(find.text('Devices'), findsOneWidget);
    });

    testWidgets('renders action label', (tester) async {
      await tester.pumpWidget(
        wrap(
          NexSectionHeader(
            title: 'Recent',
            actionLabel: 'View All',
            onAction: () {},
          ),
        ),
      );
      expect(find.text('View All'), findsOneWidget);
    });
  });

  group('NexErrorPanel', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        wrap(const NexErrorPanel(message: 'Something went wrong')),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders detail when provided', (tester) async {
      await tester.pumpWidget(
        wrap(const NexErrorPanel(message: 'Error', detail: 'Network timeout')),
      );
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        wrap(NexErrorPanel(message: 'Oops', onRetry: () {})),
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('NexOfflinePanel', () {
    testWidgets('renders offline message', (tester) async {
      await tester.pumpWidget(wrap(const NexOfflinePanel()));
      expect(find.text('No connection'), findsOneWidget);
    });

    testWidgets('shows retry button', (tester) async {
      await tester.pumpWidget(wrap(NexOfflinePanel(onRetry: () {})));
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('NexLoadingSkeleton', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 200,
            child: NexLoadingSkeleton(width: 100, height: 20),
          ),
        ),
      );
      await tester.pump();
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container, isNotNull);
    });

    testWidgets('circle variant renders', (tester) async {
      await tester.pumpWidget(wrap(const NexLoadingSkeleton.circle(size: 40)));
      await tester.pump();
      expect(find.byType(NexLoadingSkeleton), findsOneWidget);
    });

    testWidgets('text variant renders', (tester) async {
      await tester.pumpWidget(wrap(const NexLoadingSkeleton.text(width: 120)));
      await tester.pump();
      expect(find.byType(NexLoadingSkeleton), findsOneWidget);
    });
  });

  group('NexCardSkeleton', () {
    testWidgets('renders with default lines', (tester) async {
      await tester.pumpWidget(wrap(const NexCardSkeleton()));
      await tester.pump();
      expect(find.byType(NexCardSkeleton), findsOneWidget);
    });
  });

  group('NexIntegrationCard', () {
    testWidgets('renders name and status', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexIntegrationCard(
            name: 'MQTT',
            icon: Icons.router,
            status: IntegrationStatus.connected,
          ),
        ),
      );
      expect(find.text('MQTT'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('shows Coming Soon for comingSoon status', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexIntegrationCard(
            name: 'Matter',
            icon: Icons.hub,
            status: IntegrationStatus.comingSoon,
          ),
        ),
      );
      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('shows Not Available for notImplemented', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NexIntegrationCard(
            name: 'IFTTT',
            icon: Icons.link,
            status: IntegrationStatus.notImplemented,
          ),
        ),
      );
      expect(find.text('Not Available'), findsOneWidget);
    });

    test('all integration statuses have unique names', () {
      final names = IntegrationStatus.values.map((s) => s.name).toSet();
      expect(names.length, IntegrationStatus.values.length);
    });
  });

  group('ResponsiveGrid', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        wrap(const ResponsiveGrid(children: [Text('A'), Text('B')])),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────
  // 7. Widget registry preservation
  // ──────────────────────────────────────────────────────────

  group('Widget registry (Phase 6 + Phase 9)', () {
    setUpAll(() {
      registerAllWidgets();
    });

    test('NexWidgetType has exactly 47 values', () {
      expect(NexWidgetType.values.length, 47);
    });

    test('widget categories cover 6 groups', () {
      expect(WidgetCategory.values.length, 6);
    });

    test('control widgets present', () {
      expect(NexWidgetType.values, contains(NexWidgetType.switchControl));
      expect(NexWidgetType.values, contains(NexWidgetType.button));
      expect(NexWidgetType.values, contains(NexWidgetType.slider));
    });

    test('alarm widgets present (Phase 9)', () {
      expect(NexWidgetType.values, contains(NexWidgetType.alarmCount));
      expect(NexWidgetType.values, contains(NexWidgetType.criticalAlarmCount));
      expect(
        NexWidgetType.values,
        contains(NexWidgetType.unacknowledgedAlarmCount),
      );
      expect(
        NexWidgetType.values,
        contains(NexWidgetType.alarmSeverityDistribution),
      );
      expect(NexWidgetType.values, contains(NexWidgetType.recentAlarmActivity));
    });

    test('chart widgets present', () {
      expect(NexWidgetType.values, contains(NexWidgetType.lineChart));
      expect(NexWidgetType.values, contains(NexWidgetType.barChart));
      expect(NexWidgetType.values, contains(NexWidgetType.gauge));
    });

    test('industrial widgets present', () {
      expect(NexWidgetType.values, contains(NexWidgetType.machineStatus));
      expect(NexWidgetType.values, contains(NexWidgetType.tankLevel));
      expect(NexWidgetType.values, contains(NexWidgetType.alarmPanel));
    });
  });
}
