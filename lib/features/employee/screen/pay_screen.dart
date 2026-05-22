import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/duration_formatter.dart';
import '../../auth/providers/auth_providers.dart';
import '../controller/pay_controller.dart';
import '../models/pay_summary.dart';

class PayScreen extends ConsumerWidget {
  const PayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(paySummaryProvider);
    final employee = ref.watch(selectedKioskEmployeeProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency();

    final hourlyRate = (employee?.hourlyRateCents ?? 0) / 100.0;
    final otRate = hourlyRate * (employee?.overtimeMultiplier ?? 1.5);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Pay Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MainPayCard(summary: summary),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _PayStatCard(
                    title: 'Hourly Rate',
                    value: '${currency.format(hourlyRate)}/hr',
                  ),
                  _PayStatCard(
                    title: 'OT Rate',
                    value: '${currency.format(otRate)}/hr',
                  ),
                  _PayStatCard(
                    title: 'Total Hours',
                    value: formatHm(summary.totalWorked),
                  ),
                  _PayStatCard(
                    title: 'Overtime',
                    value: formatHm(summary.overtime),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainPayCard extends StatelessWidget {
  final PaySummary summary;
  const _MainPayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Week Estimate',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(summary.estimatedPay),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniLabel(label: 'Worked', value: formatHm(summary.totalWorked)),
              const SizedBox(width: 20),
              _MiniLabel(label: 'Overtime', value: formatHm(summary.overtime)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String label;
  final String value;
  const _MiniLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PayStatCard extends StatelessWidget {
  final String title;
  final String value;

  const _PayStatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
