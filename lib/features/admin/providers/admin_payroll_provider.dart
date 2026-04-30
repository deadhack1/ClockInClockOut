import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_payroll_summary.dart';
import '../../../core/utils/date_utils.dart';
import 'admin_timesheet_provider.dart';

const double hourlyRate = 20.0;
const double overtimeMultiplier = 1.5;

final adminPayrollProvider = Provider<List<AdminPayrollSummary>>((ref) {
  final entriesAsync = ref.watch(adminTimesheetProvider);

  return entriesAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (entries) {
      final Map<String, List<dynamic>> grouped = {};

      // 1. group by employee
      for (final e in entries) {
        grouped.putIfAbsent(e.employeeName, () => []);
        grouped[e.employeeName]!.add(e);
      }

      return grouped.entries.map((empEntry) {
        final name = empEntry.key;
        final shifts = empEntry.value;

        // 2. group by week
        final Map<DateTime, List<dynamic>> weekly = {};

        for (final s in shifts) {
          final week = startOfWeek(s.clockIn);

          weekly.putIfAbsent(week, () => []);
          weekly[week]!.add(s);
        }

        int totalMinutes = 0;
        int overtimeMinutes = 0;

        // 3. calculate per week
        for (final weekEntry in weekly.entries) {
          final weekShifts = weekEntry.value;

          final weekMinutes = weekShifts.fold<num>(
            0,
            (sum, s) => sum + s.worked.inMinutes,
          );

          if (weekMinutes > 2400) {
            overtimeMinutes += (weekMinutes.toInt() - 2400);
            totalMinutes += 2400;
          } else {
            totalMinutes += weekMinutes.toInt();
          }
        }

        final regularMinutes = totalMinutes;

        final regularPay = (regularMinutes / 60) * hourlyRate;
        final overtimePay =
            (overtimeMinutes / 60) * hourlyRate * overtimeMultiplier;

        return AdminPayrollSummary(
          employeeName: name,
          totalWorked: Duration(minutes: totalMinutes + overtimeMinutes),
          overtime: Duration(minutes: overtimeMinutes),
          totalPay: regularPay + overtimePay,
        );
      }).toList();
    },
  );
});
