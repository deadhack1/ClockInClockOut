import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/formatters/duration_formatter.dart';
import '../../employee/controller/pay_controller.dart';
import '../../employee/controller/timesheet_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(timesheetControllerProvider);
    final pay = ref.watch(paySummaryProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
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

            return Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _AdminCard(
                        title: 'Completed Shifts',
                        value: '$totalShifts',
                      ),
                      _AdminCard(
                        title: 'Worked Hours',
                        value: formatHm(totalHours),
                      ),
                      _AdminCard(
                        title: 'Payroll Estimate',
                        value: '\$${pay.estimatedPay.toStringAsFixed(2)}',
                      ),
                      _AdminCard(
                        title: 'Overtime',
                        value: formatHm(pay.overtime),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Activity list
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
                        tileColor: cs.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: const Text('Employee Shift'),
                        subtitle: Text(
                          'Worked ${formatHm(e.worked)}',
                        ),
                        trailing: Text(
                          '${e.clockOut.hour}:${e.clockOut.minute.toString().padLeft(2, '0')}',
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
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}