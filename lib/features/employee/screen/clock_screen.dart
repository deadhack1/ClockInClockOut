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
import '../providers/active_shifts_provider.dart';
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
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile?.role != UserRole.admin) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && ref.read(selectedKioskEmployeeProvider) != null) {
        ref.read(selectedKioskEmployeeProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out due to inactivity')),
        );
      }
    });
  }

  void _showPunchCodeDialog(Profile employee) {
    if (employee.password == null) {
      _showSetPunchCodeDialog(employee);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login as ${employee.fullName}'),
          content: TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Enter Password'),
            obscureText: true,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (CryptoUtils.verifyPassword(
                    _passwordController.text, employee.password!)) {
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

  void _showSetPunchCodeDialog(Profile employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Punch Code for ${employee.fullName}'),
        content: TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Enter New Punch Code'),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                final newCode = _passwordController.text.trim();
                if (newCode.isEmpty) return;

                final hashedCode = CryptoUtils.hashPassword(newCode);
                ref.read(authRepositoryProvider).updateEmployee(
                  employee.id,
                  {'encrypted_punch_code': hashedCode},
                );

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

  @override
  Widget build(BuildContext context) {
    final selectedEmployee = ref.watch(selectedKioskEmployeeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    if (selectedEmployee == null) {
      _inactivityTimer?.cancel();
      if (profile?.role == UserRole.employee) {
        return const Center(child: CircularProgressIndicator());
      }
      return _EmployeePicker(onSelect: _showPunchCodeDialog);
    }

    _resetInactivityTimer();

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(employee: selectedEmployee),
              const SizedBox(height: 12),
              const _StatusCard(),
              const SizedBox(height: 16),
              const _TimerCard(),
              const SizedBox(height: 18),
              _ClockActions(employeeId: selectedEmployee.id),
              const SizedBox(height: 18),
              const _StatsGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeePicker extends ConsumerWidget {
  final Function(Profile) onSelect;
  const _EmployeePicker({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(organizationEmployeesProvider);
    final activeShiftsAsync = ref.watch(activeShiftsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return employeesAsync.when(
      data: (employees) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          final activeShifts = activeShiftsAsync.valueOrNull ?? {};
          final clockInTime = activeShifts[emp.id];
          final isClockedIn = clockInTime != null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isClockedIn ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isClockedIn
                    ? Colors.green.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: isClockedIn ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isClockedIn
                    ? Colors.green.withValues(alpha: 0.1)
                    : cs.surfaceContainerHigh,
                child: Icon(
                  Icons.person,
                  color: isClockedIn ? Colors.green : cs.onSurfaceVariant,
                ),
              ),
              title: Text(
                emp.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isClockedIn ? Colors.green.shade800 : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isClockedIn)
                    Text(
                      'Clocked in at ${DateFormat('h:mm a').format(clockInTime!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    )
                  else
                    const Text('Not clocked in', style: TextStyle(fontSize: 12)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickAction(
                    isClockedIn: isClockedIn,
                    onPressed: () async {
                      final repo = ref.read(timesheetRepositoryProvider);
                      if (isClockedIn) {
                        await repo.clockOut(emp.id);
                      } else {
                        await repo.clockIn(emp.id);
                      }
                      ref.invalidate(activeShiftsProvider);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => onSelect(emp),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final bool isClockedIn;
  final VoidCallback onPressed;

  const _QuickAction({required this.isClockedIn, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isClockedIn
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        foregroundColor: isClockedIn ? Colors.red : Colors.green,
      ),
      icon: Icon(isClockedIn ? Icons.stop : Icons.play_arrow),
      tooltip: isClockedIn ? 'Quick Clock Out' : 'Quick Clock In',
    );
  }
}

class _Header extends ConsumerWidget {
  final Profile employee;
  const _Header({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin =
        ref.watch(userProfileProvider).valueOrNull?.role == UserRole.admin;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${employee.fullName}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text('Clocking System',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const Spacer(),
        if (isAdmin)
          IconButton(
            onPressed: () =>
                ref.read(selectedKioskEmployeeProvider.notifier).state = null,
            icon: const Icon(Icons.logout),
            tooltip: 'Switch User',
          ),
      ],
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final cs = Theme.of(context).colorScheme;

    final statusText = shift.isClockedIn
        ? (shift.onBreak ? 'On break' : 'On shift')
        : 'Off shift';
    final statusDot = shift.isClockedIn
        ? (shift.onBreak ? Colors.orange : Colors.green)
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $statusText',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (shift.isClockedIn && shift.clockInAt != null)
                  Text(
                    'Started at ${DateFormat('h:mm a').format(shift.clockInAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text('Today', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  const _TimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(shift.isClockedIn ? 'Shift Timer' : 'Ready',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            formatHms(shift.elapsed),
            style: const TextStyle(
                fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
            Text('Breaks: ${formatHm(shift.breakElapsed)}',
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _ClockActions extends ConsumerWidget {
  final String employeeId;
  const _ClockActions({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final ctrl = ref.read(shiftControllerProvider.notifier);

    final primaryLabel = shift.isClockedIn ? 'Clock Out' : 'Clock In';
    final primaryIcon =
        shift.isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: () => shift.isClockedIn
                ? ctrl.clockOut(employeeId)
                : ctrl.clockIn(employeeId),
            icon: Icon(primaryIcon),
            label: Text(primaryLabel,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (shift.isClockedIn && !shift.onBreak)
                    ? ctrl.startBreak
                    : null,
                icon: const Icon(Icons.coffee),
                label: const Text('Start Break'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (shift.isClockedIn && shift.onBreak)
                    ? ctrl.endBreak
                    : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('End Break'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftControllerProvider);
    final paySummary = ref.watch(paySummaryProvider);
    final currencyFormat = NumberFormat.simpleCurrency();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _MiniCard(title: "Today’s Hours", value: formatHm(shift.elapsed)),
        _MiniCard(title: "This Week", value: formatHm(paySummary.totalWorked)),
        _MiniCard(title: "Overtime", value: formatHm(paySummary.overtime)),
        _MiniCard(
            title: "Est. Pay",
            value: currencyFormat.format(paySummary.estimatedPay)),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
