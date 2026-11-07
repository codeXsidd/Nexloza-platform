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
import '../features/devices/presentation/screens/devices_screen.dart';
import '../features/devices/presentation/screens/device_detail_screen.dart';
import '../features/devices/presentation/screens/add_device_screen.dart';
import '../features/automations/presentation/screens/automations_screen.dart';
import '../features/automations/presentation/screens/create_automation_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                name: RouteNames.projects,
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
                    builder: (context, state) => ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                    path: ':id',
                    name: RouteNames.deviceDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => DeviceDetailScreen(
                      deviceId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                name: RouteNames.aiAssistant,
                builder: (context, state) => const AiAssistantScreen(),
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
        path: '/settings',
        name: RouteNames.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
