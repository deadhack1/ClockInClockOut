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

    return profileAsync.when(
      data: (profile) {
        final isAdmin = profile?.role == UserRole.admin;
        final selectedEmployee = ref.watch(selectedKioskEmployeeProvider);

        // If an employee is logged into the app, auto-select their profile for the kiosk
        if (profile != null &&
            profile.role == UserRole.employee &&
            selectedEmployee == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedKioskEmployeeProvider.notifier).state = profile;
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(selectedEmployee != null
                ? 'Clock - ${selectedEmployee.fullName}'
                : 'Employee Dashboard'),
            actions: [
              IconButton(
                onPressed: () {
                  ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: navigationShell,
          bottomNavigationBar: (isAdmin || selectedEmployee != null)
              ? NavigationBar(
                  selectedIndex: isAdmin
                      ? (navigationShell.currentIndex == 0 ? 0 : 1)
                      : navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    if (isAdmin) {
                      if (index == 0) navigationShell.goBranch(0);
                      if (index == 1) _showAdminPasswordDialog(context, ref);
                    } else {
                      navigationShell.goBranch(index);
                    }
                  },
                  destinations: [
                    const NavigationDestination(
                        icon: Icon(Icons.access_time), label: 'Clock'),
                    if (!isAdmin) ...[
                      const NavigationDestination(
                          icon: Icon(Icons.list_alt), label: 'Timesheets'),
                      const NavigationDestination(
                          icon: Icon(Icons.payments_outlined), label: 'Pay'),
                    ],
                    if (isAdmin)
                      const NavigationDestination(
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          label: 'Admin'),
                  ],
                )
              : null,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  void _showAdminPasswordDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final user = ref.read(currentUserProvider);
    final email = user?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Admin email not found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Please enter your password to return to the Admin Dashboard.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;

              try {
                // Re-authenticate to verify password
                await ref.read(authRepositoryProvider).signIn(
                      email: email,
                      password: password,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/admin');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
