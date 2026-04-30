import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/screens/admin_dashboard.dart';
import '../features/auth/models/profile.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/employee/screen/clock_screen.dart';
import '../features/employee/screen/employee_shell.dart';
import '../features/employee/screen/pay_screen.dart';
import '../features/employee/screen/timesheet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/employee/clock',
    redirect: (context, state) {
      final authValue = authState.valueOrNull;
      final isLoggedIn = authValue?.session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/employee/clock';
      }

      // Role-based protection for /admin
      if (state.matchedLocation.startsWith('/admin')) {
        final profile = profileAsync.valueOrNull;
        if (profile == null) return null; // Wait for profile to load
        if (profile.role != UserRole.admin) {
          return '/employee/clock'; // Redirect non-admins back to employee area
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
