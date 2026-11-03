import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexioza/core/router/navigation_shell.dart';
import 'package:nexioza/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nexioza/features/auth/presentation/screens/login_screen.dart';
import 'package:nexioza/features/auth/presentation/screens/signup_screen.dart';
import 'package:nexioza/features/home/presentation/screens/home_screen.dart';
import 'package:nexioza/features/invitations/presentation/screens/invitations_screen.dart';
import 'package:nexioza/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:nexioza/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:nexioza/features/organizations/presentation/screens/organization_detail_screen.dart';
import 'package:nexioza/features/organizations/presentation/screens/organization_members_screen.dart';
import 'package:nexioza/features/organizations/presentation/screens/organizations_screen.dart';
import 'package:nexioza/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:nexioza/features/projects/presentation/screens/create_project_screen.dart';
import 'package:nexioza/features/projects/presentation/screens/edit_project_screen.dart';
import 'package:nexioza/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:nexioza/features/projects/presentation/screens/projects_screen.dart';
import 'package:nexioza/features/projects/presentation/screens/templates_screen.dart';
import 'package:nexioza/features/settings/presentation/screens/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated =
          session != null &&
          (session.expiresAt == null ||
              DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
                  .isAfter(DateTime.now()));
      final location = state.matchedLocation;
      final isOnAuth = location.startsWith('/auth');
      final isOnSplash = location == '/splash';

      if (isOnSplash) return null;
      if (!isAuthenticated && !isOnAuth) return '/auth/login';
      if (isAuthenticated && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/projects/create',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/projects/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) =>
            ProjectDetailScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        builder: (context, state) =>
            EditProjectScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/organizations/:id',
        builder: (context, state) =>
            OrganizationDetailScreen(orgId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/organizations/:id/members',
        builder: (context, state) =>
            OrganizationMembersScreen(orgId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/invitations',
        builder: (context, state) => const InvitationsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/organizations',
                builder: (context, state) => const OrganizationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
