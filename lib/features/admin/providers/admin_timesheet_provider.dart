import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/admin_timesheet_entry.dart';

final adminTimesheetProvider = FutureProvider<List<AdminTimesheetEntry>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  
  try {
    // Fetching all entries. Joining with profiles for names AND break_entries for break calculation.
    final response = await supabase
        .from('time_entries')
        .select('*, profiles(full_name), break_entries(break_start, break_end)')
        .order('clock_in', ascending: false);

    return (response as List).map((e) {
      final clockIn = DateTime.parse(e['clock_in']);
      final clockOut = e['clock_out'] != null ? DateTime.parse(e['clock_out']) : DateTime.now();
      
      // Calculate total break duration from break_entries table
      final breakEntries = e['break_entries'] as List? ?? [];
      Duration totalBreaks = Duration.zero;
      for (var b in breakEntries) {
        if (b['break_start'] != null && b['break_end'] != null) {
          final start = DateTime.parse(b['break_start']);
          final end = DateTime.parse(b['break_end']);
          totalBreaks += end.difference(start);
        }
      }

      // Calculate worked time: (Clock Out - Clock In) - Total Breaks
      final totalWorked = clockOut.difference(clockIn) - totalBreaks;

      return AdminTimesheetEntry(
        id: e['id'].toString(),
        employeeId: e['employee_id'] as String,
        employeeName: (e['profiles'] as Map?)?['full_name'] as String? ?? 'Unknown Employee',
        clockIn: clockIn,
        clockOut: clockOut,
        worked: totalWorked,
        breaks: totalBreaks,
      );
    }).toList();
  } catch (e) {
    print('Admin fetch error: $e');
    return [];
  }
});
