import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/duration_formatter.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../auth/models/profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../controller/pay_controller.dart';
import '../controller/shift_controller.dart';
import '../providers/repository_providers.dart';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  final _passwordController = TextEditingController();
  Timer? _inactivityTimer;

  @override
  void dispose() {
    _passwordController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    // Auto-logout after 60 seconds of inactivity
    _inactivityTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && ref.read(selectedKioskEmployeeProvider) != null) {
        ref.read(selectedKioskEmployeeProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out due to inactivity')),
        );
      }
    });
  }

  void _setPunchCodeDialog(Profile employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Punch Code for ${employee.fullName}'),
        content: TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Enter New Punch Code'),
          obscureText: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                final newCode = _passwordController.text.trim();
                if (newCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Punch code cannot be empty')));
                  return;
                }
                final hashedCode = CryptoUtils.hashPassword(newCode);
                var result = ref.read(authRepositoryProvider).updateEmployee(
                  employee.id,
                  {'encrypted_punch_code': hashedCode},
                );
                print(result.toString());

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Punch code updated successfully')));
                _passwordController.clear();
                Navigator.pop(context);
              },
              child: const Text('Set Code')),
        ],
      ),
    );
  }

  void _showPunchCodeDialog(Profile employee) {
    print("${employee.toJson()}");
    if (employee.password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No punch code set for this employee. Please set one now.')),
      );
      return _setPunchCodeDialog(employee);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login as ${employee.fullName}'),
          content: TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Enter Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final hashedPassword = employee.password;
                if (hashedPassword == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No password set for this employee')),
                  );
                  return _setPunchCodeDialog(employee);
                }
                if (hashedPassword != null &&
                    CryptoUtils.verifyPassword(
                        _passwordController.text, hashedPassword)) {
                  ref.read(selectedKioskEmployeeProvider.notifier).state =
                      employee;
                  _passwordController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedEmployee = ref.watch(selectedKioskEmployeeProvider);
    final employeesAsync = ref.watch(organizationEmployeesProvider);

    if (selectedEmployee == null) {
      _inactivityTimer?.cancel();
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Employee',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: employeesAsync.when(
          data: (employees) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(emp.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPunchCodeDialog(emp),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading employees: $e')),
        ),
      );
    }

    final shift = ref.watch(shiftControllerProvider);
    final ctrl = ref.read(shiftControllerProvider.notifier);

    Future<void> handleClockAction() async {
      try {
        if (shift.isClockedIn) {
          ctrl.clockOut(selectedEmployee.id);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //       content: Text('Clocked out successfully! cReturning to menu...'),
          //       duration: Duration(seconds: 2)),
          // );
        } else {
          ctrl.clockIn(selectedEmployee.id);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //       content: Text('Clocked in successfully! Returning to menu...'),
          //       duration: Duration(seconds: 2)),
          // );
        }

        // Auto-logout after 2.5 seconds to allow user to see the change
        // await Future.delayed(const Duration(milliseconds: 2500));
        // if (mounted &&
        //     ref.read(selectedKioskEmployeeProvider) == selectedEmployee) {
        //   ref.read(selectedKioskEmployeeProvider.notifier).state = null;
        // }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    final statusText = shift.isClockedIn
        ? (shift.onBreak ? 'On break' : 'On shift')
        : 'Off shift';

    final statusDot = shift.isClockedIn
        ? (shift.onBreak ? Colors.orange : Colors.green)
        : Colors.grey;

    final primaryLabel = shift.isClockedIn ? 'Clock Out' : 'Clock In';
    final primaryIcon =
        shift.isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded;

    final breakPrimaryEnabled = shift.isClockedIn && !shift.onBreak;
    final breakEndEnabled = shift.isClockedIn && shift.onBreak;

    final paySummary = ref.watch(paySummaryProvider);
    final currencyFormat = NumberFormat.simpleCurrency();

    _resetInactivityTimer();

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${selectedEmployee.fullName}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Clocking System',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref
                        .read(selectedKioskEmployeeProvider.notifier)
                        .state = null,
                    icon: const Icon(Icons.logout),
                    tooltip: 'Switch User',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: statusDot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: $statusText',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('Today', style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Timer card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      shift.isClockedIn ? 'Shift Timer' : 'Ready',
                      style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatHms(shift.elapsed),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shift.isClockedIn
                          ? (shift.onBreak ? 'Break running' : 'Tracking time')
                          : 'Clock in to start tracking',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if (shift.breakElapsed > Duration.zero) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Breaks: ${formatHm(shift.breakElapsed)}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Clock In / Out button
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: handleClockAction,
                  icon: Icon(primaryIcon),
                  label: Text(
                    primaryLabel,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Break buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: breakPrimaryEnabled ? ctrl.startBreak : null,
                      icon: const Icon(Icons.coffee),
                      label: const Text('Start Break'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: breakEndEnabled ? ctrl.endBreak : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('End Break'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Stats wired to paySummaryProvider
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _MiniCard(
                        title: "Today’s Hours", value: formatHm(shift.elapsed)),
                    _MiniCard(
                        title: "This Week",
                        value: formatHm(paySummary.totalWorked)),
                    _MiniCard(
                        title: "Overtime",
                        value: formatHm(paySummary.overtime)),
                    _MiniCard(
                        title: "Est. Pay",
                        value: currencyFormat.format(paySummary.estimatedPay)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  const _MiniCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
