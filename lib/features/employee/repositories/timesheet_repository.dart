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

    await client.from('time_entries').insert({
      'employee_id': userId,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': clockOut.toIso8601String(),
      'worked_minutes': worked.inMinutes,
      'break_minutes': breaks.inMinutes,
    });
  }

  Future<List<TimesheetEntry>> fetchEntries() async {
    final userId = client.auth.currentUser!.id;

    final response = await client
        .from('time_entries')
        .select()
        .eq('employee_id', userId)
        .order('clock_in', ascending: false);

    return (response as List)
        .map(
          (e) => TimesheetEntry(
        id: e['id'].toString(),
        clockIn: DateTime.parse(e['clock_in']),
        clockOut: DateTime.parse(e['clock_out']),
        worked: Duration(minutes: e['worked_minutes']),
        breaks: Duration(minutes: e['break_minutes']),
      ),
    )
        .toList();
  }
}