import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/duration_formatter.dart';
import '../providers/admin_payroll_provider.dart';
import '../providers/admin_timesheet_provider.dart';

import '../providers/payroll_export_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(adminTimesheetProvider);
    final payroll = ref.watch(adminPayrollProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => context.go('/employee/clock'),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.file_download),
      //       tooltip: 'Export Payroll',
      //       onPressed: () => ref.read(payrollExportProvider).exportToCsv(),
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (entries) {
              final totalShifts = entries.length;
              final totalHours = entries.fold<Duration>(
                Duration.zero,
                (sum, e) => sum + e.worked,
              );

              final totalPay = payroll.fold<double>(
                0,
                (sum, p) => sum + p.totalPay,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  SizedBox(
                    height: 200,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _AdminCard(
                          title: 'Total Shifts',
                          value: '$totalShifts',
                        ),
                        _AdminCard(
                          title: 'Staff Hours',
                          value: formatHm(totalHours),
                        ),
                        _AdminCard(
                          title: 'Total Payroll',
                          value: '\$${totalPay.toStringAsFixed(2)}',
                        ),
                        _AdminCard(
                          title: 'Active Staff',
                          value: '${payroll.length}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Recent Staff Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'No staff activity yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final e = entries[index];

                              return ListTile(
                                tileColor: cs.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  e.employeeName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Worked ${formatHm(e.worked)} • ${e.clockIn.month}/${e.clockIn.day}',
                                ),
                                trailing: Text(
                                  '${e.clockOut.hour}:${e.clockOut.minute.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String value;

  const _AdminCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
