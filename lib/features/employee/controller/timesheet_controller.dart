import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timesheet_entry.dart';
import '../providers/repository_providers.dart';

final timesheetControllerProvider =
AsyncNotifierProvider<TimesheetController, List<TimesheetEntry>>(
  TimesheetController.new,
);

class TimesheetController extends AsyncNotifier<List<TimesheetEntry>> {
  @override
  Future<List<TimesheetEntry>> build() async {
    return _repo.fetchEntries();
  }

  get _repo => ref.read(timesheetRepositoryProvider);

  Future<void> refreshEntries() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchEntries());
  }

  Future<void> addEntry(TimesheetEntry entry) async {
    print("Trying to add the entry");
    try {
      await _repo.addEntry(
        clockIn: entry.clockIn,
        clockOut: entry.clockOut,
        worked: entry.worked,
        breaks: entry.breaks,
      );
    } on Exception catch (e) {
      print("the exact nature of the exception is $e");
      // TODO
    }

    await refreshEntries();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    await refreshEntries();
  }
}
