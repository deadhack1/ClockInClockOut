import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_payroll_summary.dart';
import '../models/admin_timesheet_entry.dart';
import '../../../core/utils/date_utils.dart';
import 'admin_timesheet_provider.dart';

final adminPayrollProvider = Provider<List<AdminPayrollSummary>>((ref) {
  final entriesAsync = ref.watch(adminTimesheetProvider);

  return entriesAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (entries) {
      final Map<String, List<AdminTimesheetEntry>> grouped = {};

      // 1. group by employee
      for (final e in entries) {
        grouped.putIfAbsent(e.employeeName, () => []);
        grouped[e.employeeName]!.add(e);
      }

      return grouped.entries.map((empEntry) {
        final name = empEntry.key;
        final shifts = empEntry.value;

        // 2. group by week
        final Map<DateTime, List<AdminTimesheetEntry>> weekly = {};

        for (final s in shifts) {
          final week = startOfWeek(s.clockIn);

          weekly.putIfAbsent(week, () => []);
          weekly[week]!.add(s);
        }

        double totalPay = 0;
        Duration totalWorkedDuration = Duration.zero;
        Duration totalOvertimeDuration = Duration.zero;

        // 3. calculate per week
        for (final weekEntry in weekly.entries) {
          final weekShifts = weekEntry.value;

          final weekMinutes = weekShifts.fold<int>(
            0,
            (sum, s) => sum + s.worked.inMinutes,
          );

          // We'll use the rate from the first shift of the week for simplicity, 
          // or ideally, rate changes should be handled per shift.
          final firstShift = weekShifts.first;
          final hourlyRate = firstShift.hourlyRateCents / 100.0;
          final multiplier = firstShift.overtimeMultiplier;

          int weeklyRegularMinutes = 0;
          int weeklyOvertimeMinutes = 0;

          if (weekMinutes > 2400) { // 40 hours
            weeklyOvertimeMinutes = weekMinutes - 2400;
            weeklyRegularMinutes = 2400;
          } else {
            weeklyRegularMinutes = weekMinutes;
          }

          final weeklyPay = (weeklyRegularMinutes / 60.0 * hourlyRate) + 
                            (weeklyOvertimeMinutes / 60.0 * hourlyRate * multiplier);
          
          totalPay += weeklyPay;
          totalWorkedDuration += Duration(minutes: weekMinutes);
          totalOvertimeDuration += Duration(minutes: weeklyOvertimeMinutes);
        }

        return AdminPayrollSummary(
          employeeName: name,
          totalWorked: totalWorkedDuration,
          overtime: totalOvertimeDuration,
          totalPay: totalPay,
        );
      }).toList();
    },
  );
});
