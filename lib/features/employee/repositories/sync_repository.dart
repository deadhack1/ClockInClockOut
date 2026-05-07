import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timesheet_entry.dart';
import 'timesheet_repository.dart';

class SyncRepository {
  final SharedPreferences prefs;
  final TimesheetRepository timesheetRepo;
  final SupabaseClient supabase;

  static const String _syncQueueKey = 'offline_sync_queue';

  SyncRepository({
    required this.prefs,
    required this.timesheetRepo,
    required this.supabase,
  });

  Future<void> queueEntry(TimesheetEntry entry) async {
    final queue = _getQueue();
    queue.add(entry.toJson());
    await prefs.setString(_syncQueueKey, jsonEncode(queue));
    
    // Try to sync immediately
    attemptSync();
  }

  List<Map<String, dynamic>> _getQueue() {
    final String? data = prefs.getString(_syncQueueKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> attemptSync() async {
    final queue = _getQueue();
    if (queue.isEmpty) return;

    debugPrint('Attempting to sync ${queue.length} entries...');

    List<Map<String, dynamic>> remaining = [];

    for (var entryJson in queue) {
      try {
        final entry = TimesheetEntry.fromJson(entryJson);
        await timesheetRepo.addEntry(entry);
      } catch (e) {
        debugPrint('Failed to sync entry: $e');
        remaining.add(entryJson);
      }
    }

    await prefs.setString(_syncQueueKey, jsonEncode(remaining));
  }
}
