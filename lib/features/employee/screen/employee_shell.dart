import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmployeeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const EmployeeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Clock'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Timesheets'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Pay'),
        ],
      ),
    );
  }
}
