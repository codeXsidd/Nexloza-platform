import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../features/authentication/presentation/screens/email_verification_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/projects/presentation/screens/projects_screen.dart';
import '../features/projects/presentation/screens/project_detail_screen.dart';
import '../features/projects/presentation/screens/create_project_screen.dart';
import '../features/projects/presentation/screens/edit_project_screen.dart';
import '../features/devices/presentation/screens/devices_screen.dart';
import '../features/devices/presentation/screens/device_detail_screen.dart';
import '../features/devices/presentation/screens/add_device_screen.dart';
import '../features/devices/presentation/screens/edit_device_screen.dart';
import '../features/devices/presentation/screens/manage_sensors_screen.dart';
import '../features/devices/presentation/screens/manage_actuators_screen.dart';
import '../features/devices/presentation/screens/device_pairing_screen.dart';
import '../features/automations/presentation/screens/automations_screen.dart';
import '../features/automations/presentation/screens/create_automation_screen.dart';
import '../features/automations/presentation/screens/automation_detail_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/api_keys_screen.dart';
import '../features/organizations/presentation/screens/organizations_screen.dart';
import '../features/organizations/presentation/screens/create_organization_screen.dart';
import '../features/organizations/presentation/screens/organization_detail_screen.dart';
import '../features/invitations/presentation/screens/invitations_screen.dart';
import '../features/device_studio/presentation/screens/device_studio_screen.dart';
import '../features/dashboards/presentation/screens/dashboards_screen.dart';
import '../features/dashboards/presentation/screens/create_dashboard_screen.dart';
import '../features/dashboards/presentation/screens/dashboard_editor_screen.dart';
import '../features/virtual_devices/presentation/screens/virtual_devices_screen.dart';
import '../features/virtual_devices/presentation/screens/create_virtual_device_screen.dart';
import '../features/virtual_devices/presentation/screens/simulator_control_screen.dart';
import '../features/virtual_devices/presentation/screens/digital_twin_screen.dart';
import '../features/scenes/presentation/screens/scenes_screen.dart';
import '../features/scenes/presentation/screens/create_scene_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/integrations/presentation/screens/integrations_screen.dart';
import '../features/alarms/presentation/screens/alarms_overview_screen.dart';
import '../features/alarms/presentation/screens/active_alarms_screen.dart';
import '../features/alarms/presentation/screens/alarm_history_screen.dart';
import '../features/alarms/presentation/screens/alarm_detail_screen.dart';
import '../features/alarms/presentation/screens/alarm_config_screen.dart';
import '../features/alarms/presentation/screens/create_alarm_config_screen.dart';
import '../features/alarms/presentation/screens/escalation_policies_screen.dart';
import '../features/alarms/presentation/screens/escalation_policy_detail_screen.dart';
import '../features/alarms/presentation/screens/notification_preferences_screen.dart';
import '../features/rule_engine/presentation/screens/rules_list_screen.dart';
import '../features/rule_engine/presentation/screens/create_rule_screen.dart';
import '../features/rule_engine/presentation/screens/rule_detail_screen.dart';
import '../features/rule_engine/presentation/screens/rule_editor_screen.dart';
import '../features/rule_engine/presentation/screens/execution_history_screen.dart';
import '../features/rule_engine/presentation/screens/execution_detail_screen.dart';
import '../features/rule_engine/presentation/screens/rule_dry_run_screen.dart';
import '../features/device_templates/presentation/screens/device_templates_screen.dart';
import '../features/firmware/presentation/screens/firmware_screen.dart';
import '../features/developer_tools/presentation/screens/developer_tools_screen.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/not_found_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final status = authState.status;
      final location = state.matchedLocation;

      const authRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/email-verification',
      ];
      final isAuthRoute = authRoutes.contains(location);
      final isSplash = location == '/splash';

      if (status == AuthStatus.initial) {
        return isSplash ? null : '/splash';
      }

      final isAuthenticated = status == AuthStatus.authenticated;

      if (!isAuthenticated && !isAuthRoute && !isSplash) return '/login';
      if (isAuthenticated && (isAuthRoute || isSplash)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: RouteNames.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Main shell: 5 branches for mobile bottom nav
      // Branch 0: Home, Branch 1: Devices, Branch 2: Automation,
      // Branch 3: Analytics, Branch 4: Settings
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Devices
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/devices',
                name: RouteNames.devices,
                builder: (context, state) => const DevicesScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: RouteNames.addDevice,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddDeviceScreen(),
                  ),
                  GoRoute(
                    path: 'pair',
                    name: RouteNames.pairDevice,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const DevicePairingScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.deviceDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => DeviceDetailScreen(
                      deviceId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.editDevice,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => EditDeviceScreen(
                          deviceId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'sensors',
                        name: RouteNames.manageSensors,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ManageSensorsScreen(
                          deviceId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'actuators',
                        name: RouteNames.manageActuators,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ManageActuatorsScreen(
                          deviceId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Automation
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/automations',
                name: RouteNames.automations,
                builder: (context, state) => const AutomationsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: RouteNames.createAutomation,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateAutomationScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.automationDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => AutomationDetailScreen(
                      automationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                name: RouteNames.analytics,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),

          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level routes (accessible from sidebar, push on top of shell)
      GoRoute(
        path: '/projects',
        name: RouteNames.projects,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProjectsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createProject,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CreateProjectScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.projectDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                ProjectDetailScreen(projectId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.editProject,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    EditProjectScreen(projectId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/api-keys',
        name: RouteNames.apiKeys,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ApiKeysScreen(),
      ),
      GoRoute(
        path: '/organizations',
        name: RouteNames.organizations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OrganizationsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createOrganization,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CreateOrganizationScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.organizationDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => OrganizationDetailScreen(
              organizationId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/invitations',
        name: RouteNames.invitations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const InvitationsScreen(),
      ),
      GoRoute(
        path: '/ai',
        name: RouteNames.aiAssistant,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/device-studio',
        name: RouteNames.deviceStudio,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeviceStudioScreen(),
      ),
      GoRoute(
        path: '/dashboards',
        name: RouteNames.dashboards,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DashboardsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createDashboard,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CreateDashboardScreen(),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.dashboardEditor,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                DashboardEditorScreen(dashboardId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/scenes',
        name: RouteNames.scenes,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScenesScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createScene,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CreateSceneScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/integrations',
        name: RouteNames.integrations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IntegrationsScreen(),
      ),
      GoRoute(
        path: '/virtual-devices',
        name: RouteNames.virtualDevices,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => VirtualDevicesScreen(
          projectId: state.uri.queryParameters['projectId'] ?? '',
          organizationId: state.uri.queryParameters['organizationId'] ?? '',
        ),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createVirtualDevice,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const CreateVirtualDeviceScreen(),
          ),
          GoRoute(
            path: ':id/simulator',
            name: RouteNames.simulatorControl,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SimulatorControlScreen(
              deviceId: state.pathParameters['id']!,
              projectId: state.uri.queryParameters['projectId'] ?? '',
              organizationId: state.uri.queryParameters['organizationId'] ?? '',
              profileType: state.uri.queryParameters['profile'] ?? 'smart_home',
            ),
          ),
          GoRoute(
            path: ':id/twin',
            name: RouteNames.digitalTwin,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                DigitalTwinScreen(deviceId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/rules',
        name: RouteNames.rules,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RulesListScreen(
          projectId: state.uri.queryParameters['projectId'] ?? '',
        ),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createRule,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => CreateRuleScreen(
              projectId: state.uri.queryParameters['projectId'] ?? '',
            ),
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.ruleDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                RuleDetailScreen(ruleId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'editor',
                name: RouteNames.ruleEditor,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    RuleEditorScreen(ruleId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'executions',
                name: RouteNames.ruleExecutionHistory,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    ExecutionHistoryScreen(ruleId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'dry-run',
                name: RouteNames.ruleDryRun,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    RuleDryRunScreen(automationId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'execution/:executionId',
            name: RouteNames.ruleExecutionDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ExecutionDetailScreen(
              executionId: state.pathParameters['executionId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/alarms',
        name: RouteNames.alarms,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AlarmsOverviewScreen(
          projectId: state.uri.queryParameters['projectId'] ?? '',
        ),
        routes: [
          GoRoute(
            path: 'active',
            name: RouteNames.activeAlarms,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ActiveAlarmsScreen(
              projectId: state.uri.queryParameters['projectId'] ?? '',
            ),
          ),
          GoRoute(
            path: 'history',
            name: RouteNames.alarmHistory,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => AlarmHistoryScreen(
              projectId: state.uri.queryParameters['projectId'] ?? '',
            ),
          ),
          GoRoute(
            path: 'configurations',
            name: RouteNames.alarmConfigurations,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => AlarmConfigScreen(
              projectId: state.uri.queryParameters['projectId'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: RouteNames.createAlarmConfig,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => CreateAlarmConfigScreen(
                  projectId: state.uri.queryParameters['projectId'] ?? '',
                  organizationId:
                      state.uri.queryParameters['organizationId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'escalation',
            name: RouteNames.escalationPolicies,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => EscalationPoliciesScreen(
              projectId: state.uri.queryParameters['projectId'] ?? '',
              organizationId: state.uri.queryParameters['organizationId'] ?? '',
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.escalationPolicyDetail,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => EscalationPolicyDetailScreen(
                  policyId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: ':id',
            name: RouteNames.alarmDetail,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                AlarmDetailScreen(alarmId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications/preferences',
        name: RouteNames.notificationPreferences,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),

      // Phase 10: New routes
      GoRoute(
        path: '/device-templates',
        name: RouteNames.deviceTemplates,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeviceTemplatesScreen(),
      ),
      GoRoute(
        path: '/firmware',
        name: RouteNames.firmware,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FirmwareScreen(),
      ),
      GoRoute(
        path: '/developer',
        name: RouteNames.developerTools,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeveloperToolsScreen(),
      ),
    ],
  );
});
