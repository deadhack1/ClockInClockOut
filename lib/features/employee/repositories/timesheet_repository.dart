import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timesheet_entry.dart';

class TimesheetRepository {
  final SupabaseClient client;

  TimesheetRepository(this.client);

  Future<void> addEntry(TimesheetEntry entry) async {
    // 1. Insert the main time entry
    final entryResponse = await client.from('time_entries').insert({
      'employee_id': entry.employeeId,
      'clock_in': entry.clockIn.toIso8601String(),
      'clock_out': entry.clockOut?.toIso8601String(),
      'status': entry.status,
      'notes': entry.notes,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
    }).select().single();

    final entryId = entryResponse['id'];

    // 2. Insert break entry if exists
    if (entry.breaks > Duration.zero) {
      await client.from('break_entries').insert({
        'time_entry_id': entryId,
        'break_start': entry.clockIn.toIso8601String(), // Placeholder
        'break_end': entry.clockIn.add(entry.breaks).toIso8601String(), // Placeholder
      });
    }
  }

  Future<List<TimesheetEntry>> fetchEntries(String userId) async {
    final response = await client
        .from('time_entries')
        .select('*, break_entries(break_start, break_end)')
        .eq('employee_id', userId)
        .order('clock_in', ascending: false);

    return (response as List).map((e) {
      final breakEntries = e['break_entries'] as List? ?? [];
      Duration totalBreaks = Duration.zero;
      for (var b in breakEntries) {
        if (b['break_start'] != null && b['break_end'] != null) {
          final start = DateTime.parse(b['break_start']);
          final end = DateTime.parse(b['break_end']);
          totalBreaks += end.difference(start);
        }
      }

      return TimesheetEntry.fromJson(e, totalBreaks: totalBreaks);
    }).toList();
  }

  Future<void> clearAll() async {
    final userId = client.auth.currentUser!.id;

    try {
      final userEntries = await client
          .from('time_entries')
          .select('id')
          .eq('employee_id', userId);

      final entryIds = (userEntries as List).map((e) => e['id']).toList();

      if (entryIds.isNotEmpty) {
        await client
            .from('break_entries')
            .delete()
            .inFilter('time_entry_id', entryIds);

        await client
            .from('time_entries')
            .delete().inFilter('id', entryIds);
      }
    } catch (e) {
      debugPrint("Failed to clear entries: $e");
      rethrow;
    }
  }
}
