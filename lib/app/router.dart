import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../features/admin/screens/admin_dashboard_screen.dart';
// import '../features/employee/screens/employee_shell.dart';
// import '../features/employee/screens/clock_screen.dart';
// import '../features/employee/screens/timesheets_screen.dart';
// import '../features/employee/screens/pay_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/employee/clock',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => EmployeeShell(navigationShell: navShell),
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
