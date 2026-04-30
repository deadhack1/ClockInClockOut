import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/models/profile.dart';
import '../../auth/providers/auth_providers.dart';

class EmployeeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const EmployeeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isAdmin = profileAsync.valueOrNull?.role == UserRole.admin;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            context.push('/admin');
          } else {
            navigationShell.goBranch(index);
          }
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.access_time), label: 'Clock'),
          const NavigationDestination(
              icon: Icon(Icons.list_alt), label: 'Timesheets'),
          const NavigationDestination(
              icon: Icon(Icons.payments_outlined), label: 'Pay'),
          if (isAdmin)
            const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Admin'),
        ],
      ),
    );
  }
}
