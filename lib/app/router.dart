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
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final location = state.matchedLocation;

      // 1. Handle Unauthenticated users
      if (!isLoggedIn) {
        return (location == '/login' || location == '/signup') ? null : '/login';
      }

      // 2. Handle Authenticated users - wait for profile
      final profile = profileAsync.valueOrNull;
      if (profile == null) return null;

      final isAdmin = profile.role == UserRole.admin;

      // 3. Redirect from auth routes or root to the appropriate dashboard
      if (location == '/login' || location == '/signup' || location == '/') {
        return isAdmin ? '/admin' : '/employee/clock';
      }

      // 4. Role-based protection: Only admins can access /admin
      if (location.startsWith('/admin') && !isAdmin) {
        return '/employee/clock';
      }

      // Note: We allow admins to access /employee routes (Kiosk mode)
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
