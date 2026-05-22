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

  Future<void> clockIn(String employeeId) async {
    print("Lets clock in employee: $employeeId");
    await client.from('time_entries').insert({
      'employee_id': employeeId,
      'clock_in': DateTime.now().toIso8601String(),
      'status': 'active',
    });
  }

  Future<void> clockOut(String employeeId, {Duration breaks = Duration.zero}) async {
    // Find the active entry
    final activeEntry = await client
        .from('time_entries')
        .select('id, clock_in')
        .eq('employee_id', employeeId)
        .isFilter('clock_out', null)
        .order('clock_in', ascending: false)
        .limit(1)
        .maybeSingle();

    if (activeEntry != null) {
      final now = DateTime.now();
      await client.from('time_entries').update({
        'clock_out': now.toIso8601String(),
        'status': 'completed',
      }).eq('id', activeEntry['id']);

      if (breaks > Duration.zero) {
        final clockIn = DateTime.parse(activeEntry['clock_in']);
        await client.from('break_entries').insert({
          'time_entry_id': activeEntry['id'],
          'break_start': clockIn.toIso8601String(),
          'break_end': clockIn.add(breaks).toIso8601String(),
        });
      }
    }
  }

  Future<Map<String, DateTime>> fetchActiveShifts() async {
    final response = await client
        .from('time_entries')
        .select('employee_id, clock_in')
        .isFilter('clock_out', null);
    
    final Map<String, DateTime> activeShifts = {};
    for (var entry in (response as List)) {
      activeShifts[entry['employee_id']] = DateTime.parse(entry['clock_in']);
    }
    return activeShifts;
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
}
