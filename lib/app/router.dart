import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router_utils.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/admin_shell.dart';
import '../features/admin/screens/manage_employees_screen.dart';
import '../features/admin/screens/manage_timesheets_screen.dart';
import '../features/auth/models/profile.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/employee/screen/clock_screen.dart';
import '../features/employee/screen/employee_shell.dart';
import '../features/employee/screen/pay_screen.dart';
import '../features/employee/screen/timesheet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges),
    redirect: (context, state) {
      final authValue = authState.valueOrNull;
      final isLoggedIn = authValue?.session != null;
      final location = state.matchedLocation;

      // 1. Handle Unauthenticated users
      if (!isLoggedIn) {
        if (location == '/login' || location == '/signup') return null;
        return '/login';
      }

      // 2. Handle Authenticated users - wait for profile
      final profile = profileAsync.valueOrNull;
      if (profile == null) {
        // If we are logged in but don't have a profile yet, 
        // we might be in the middle of a signup or loading.
        // Stay where we are to avoid redirect loops.
        return null; 
      }

      final isAdmin = profile.role == UserRole.admin;

      // 3. Prevent logged in users from seeing login/signup
      if (location == '/login' || location == '/signup') {
        return isAdmin ? '/admin' : '/employee/clock';
      }

      // 4. Role-based protection
      if (location.startsWith('/admin') && !isAdmin) {
        return '/employee/clock';
      }

      if (location.startsWith('/employee') && isAdmin) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            EmployeeShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employee/clock',
                builder: (context, state) => const ClockScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employee/timesheets',
                builder: (context, state) => const TimesheetsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/employee/pay',
                builder: (context, state) => const PayScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            AdminShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/manage-employees',
                builder: (context, state) => const ManageEmployeesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/manage-timesheets',
                builder: (context, state) => const ManageTimesheetsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
