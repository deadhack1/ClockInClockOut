import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pay_summary.dart';
import 'timesheet_controller.dart';

const double hourlyRate = 20.0;
const double overtimeMultiplier = 1.5;

final paySummaryProvider = Provider<PaySummary>((ref) {
  final entriesAsync = ref.watch(timesheetControllerProvider);

  return entriesAsync.when(
    loading: () => const PaySummary(
      totalWorked: Duration.zero,
      overtime: Duration.zero,
      estimatedPay: 0,
    ),

    error: (_, __) => const PaySummary(
      totalWorked: Duration.zero,
      overtime: Duration.zero,
      estimatedPay: 0,
    ),

    data: (entries) {
      final totalMinutes =
      entries.fold<int>(0, (sum, e) => sum + e.worked.inMinutes);

      final overtimeMinutes =
      totalMinutes > 2400 ? totalMinutes - 2400 : 0;

      final regularMinutes = totalMinutes - overtimeMinutes;

      final regularPay = (regularMinutes / 60) * hourlyRate;
      final overtimePay =
          (overtimeMinutes / 60) * hourlyRate * overtimeMultiplier;

      return PaySummary(
        totalWorked: Duration(minutes: totalMinutes),
        overtime: Duration(minutes: overtimeMinutes),
        estimatedPay: regularPay + overtimePay,
      );
    },
  );
});