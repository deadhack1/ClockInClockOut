import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/admin_timesheet_entry.dart';

final adminTimesheetProvider =
    AsyncNotifierProvider<AdminTimesheetController, List<AdminTimesheetEntry>>(
        AdminTimesheetController.new);

class AdminTimesheetController extends AsyncNotifier<List<AdminTimesheetEntry>> {
  @override
  Future<List<AdminTimesheetEntry>> build() async {
    return _fetch();
  }

  Future<List<AdminTimesheetEntry>> _fetch() async {
    final supabase = ref.watch(supabaseProvider);
    final profile = await ref.watch(userProfileProvider.future);

    if (profile?.organizationId == null) return [];

    try {
      final response = await supabase
          .from('time_entries')
          .select(
              '*, profiles!inner(full_name, hourly_rate_cents, overtime_multiplier, organization_id), break_entries(break_start, break_end)')
          .eq('profiles.organization_id', profile!.organizationId!)
          .order('clock_in', ascending: false);

      return (response as List).map((e) {
        final clockIn = DateTime.parse(e['clock_in']);
        final clockOut = e['clock_out'] != null
            ? DateTime.parse(e['clock_out'])
            : DateTime.now();

        final breakEntries = e['break_entries'] as List? ?? [];
        Duration totalBreaks = Duration.zero;
        for (var b in breakEntries) {
          if (b['break_start'] != null && b['break_end'] != null) {
            final start = DateTime.parse(b['break_start']);
            final end = DateTime.parse(b['break_end']);
            totalBreaks += end.difference(start);
          }
        }

        final totalWorked = clockOut.difference(clockIn) - totalBreaks;
        final profileData = e['profiles'] as Map<String, dynamic>?;

        return AdminTimesheetEntry(
          id: e['id'].toString(),
          employeeId: e['employee_id'] as String,
          employeeName:
              profileData?['full_name'] as String? ?? 'Unknown Employee',
          clockIn: clockIn,
          clockOut: clockOut,
          worked: totalWorked,
          breaks: totalBreaks,
          hourlyRateCents:
              (profileData?['hourly_rate_cents'] as num?)?.toInt() ?? 0,
          overtimeMultiplier:
              (profileData?['overtime_multiplier'] as num?)?.toDouble() ?? 1.5,
        );
      }).toList();
    } catch (e) {
      debugPrint('Admin fetch error: $e');
      return [];
    }
  }

  Future<void> deleteEntry(String entryId) async {
    final supabase = ref.read(supabaseProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Delete breaks first due to FK
      await supabase.from('break_entries').delete().eq('time_entry_id', entryId);
      await supabase.from('time_entries').delete().eq('id', entryId);
      return _fetch();
    });
  }

  Future<void> updateEntry(String entryId, DateTime clockIn, DateTime clockOut) async {
    final supabase = ref.read(supabaseProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.from('time_entries').update({
        'clock_in': clockIn.toIso8601String(),
        'clock_out': clockOut.toIso8601String(),
      }).eq('id', entryId);
      return _fetch();
    });
  }
}
