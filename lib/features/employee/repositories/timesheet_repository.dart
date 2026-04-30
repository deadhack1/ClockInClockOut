import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timesheet_entry.dart';

class TimesheetRepository {
  final SupabaseClient client;

  TimesheetRepository(this.client);

  Future<void> addEntry({
    required DateTime clockIn,
    required DateTime clockOut,
    required Duration worked,
    required Duration breaks,
  }) async {
    final userId = client.auth.currentUser!.id;

    // 1. Insert the main time entry
    final entryResponse = await client.from('time_entries').insert({
      'employee_id': userId,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': clockOut.toIso8601String(),
      'status': 'completed', // Or 'active' if it was still running
    }).select().single();

    final entryId = entryResponse['id'];

    // 2. Since the current controller only provides a total Duration for breaks,
    // and the schema expects individual break records, we'll insert one 
    // "summary" break entry if there was any break time.
    // In a full implementation, we'd record each break as it happens.
    if (breaks > Duration.zero) {
      // We don't have the exact start/end of the breaks, so we'll approximate
      // or just store the total duration by setting a dummy end time.
      // Better yet: we should ideally update the controller to track multiple breaks.
      // For now, to satisfy the schema:
      await client.from('break_entries').insert({
        'time_entry_id': entryId,
        'break_start': clockIn.toIso8601String(), // Placeholder
        'break_end': clockIn.add(breaks).toIso8601String(), // Placeholder
      });
    }
  }

  Future<List<TimesheetEntry>> fetchEntries() async {
    final userId = client.auth.currentUser!.id;

    // Fetch entries and join with break_entries to calculate total break time
    final response = await client
        .from('time_entries')
        .select('*, break_entries(break_start, break_end)')
        .eq('employee_id', userId)
        .order('clock_in', ascending: false);

    return (response as List).map((e) {
      final clockIn = DateTime.parse(e['clock_in']);
      final clockOut = e['clock_out'] != null ? DateTime.parse(e['clock_out']) : DateTime.now();
      
      // Calculate breaks from the joined break_entries
      final breakEntries = e['break_entries'] as List? ?? [];
      Duration totalBreaks = Duration.zero;
      for (var b in breakEntries) {
        if (b['break_start'] != null && b['break_end'] != null) {
          final start = DateTime.parse(b['break_start']);
          final end = DateTime.parse(b['break_end']);
          totalBreaks += end.difference(start);
        }
      }

      // If worked_minutes was in schema we'd use it, but since it's not, 
      // we calculate it: (Out - In) - Breaks
      final totalWorked = clockOut.difference(clockIn) - totalBreaks;

      return TimesheetEntry(
        id: e['id'].toString(),
        clockIn: clockIn,
        clockOut: clockOut,
        worked: totalWorked,
        breaks: totalBreaks,
      );
    }).toList();
  }

  Future<void> clearAll() async {
    final userId = client.auth.currentUser!.id;
    // Note: Due to foreign key constraints, we might need to delete breaks first 
    // if CASCADE is not set. Assuming standard Supabase setup.
    await client.from('time_entries').delete().eq('employee_id', userId);
  }
}
