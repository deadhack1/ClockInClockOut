import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/pay_summary.dart';
import 'shift_controller.dart';
import 'timesheet_controller.dart';

final paySummaryProvider = Provider<PaySummary>((ref) {
  final entriesAsync = ref.watch(timesheetControllerProvider);
  final selectedEmployee = ref.watch(selectedKioskEmployeeProvider);
  final currentShift = ref.watch(shiftControllerProvider);

  final hourlyRate = (selectedEmployee?.hourlyRateCents ?? 0) / 100.0;
  final overtimeMultiplier = selectedEmployee?.overtimeMultiplier ?? 1.5;

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
      var totalMinutes = entries.fold<int>(0, (sum, e) => sum + e.worked.inMinutes);

      // Add current active shift minutes if clocked in
      if (currentShift.isClockedIn && !currentShift.onBreak) {
        totalMinutes += currentShift.elapsed.inMinutes;
      }

      // Simple overtime calculation (e.g., > 40 hours / 2400 minutes)
      final overtimeMinutes = totalMinutes > 2400 ? totalMinutes - 2400 : 0;
      final regularMinutes = totalMinutes - overtimeMinutes;

      final regularPay = (regularMinutes / 60) * hourlyRate;
      final overtimePay = (overtimeMinutes / 60) * hourlyRate * overtimeMultiplier;

      return PaySummary(
        totalWorked: Duration(minutes: totalMinutes),
        overtime: Duration(minutes: overtimeMinutes),
        estimatedPay: regularPay + overtimePay,
      );
    },
  );
});
