import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/timesheet_entry.dart';
import '../providers/repository_providers.dart';

final timesheetControllerProvider =
AsyncNotifierProvider<TimesheetController, List<TimesheetEntry>>(
  TimesheetController.new,
);

class TimesheetController extends AsyncNotifier<List<TimesheetEntry>> {
  @override
  Future<List<TimesheetEntry>> build() async {
    final employee = ref.watch(selectedKioskEmployeeProvider);
    if (employee == null) return [];
    
    return _repo.fetchEntries(employee.id);
  }

  get _repo => ref.read(timesheetRepositoryProvider);

  Future<void> refreshEntries() async {
    final employee = ref.read(selectedKioskEmployeeProvider);
    if (employee == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.fetchEntries(employee.id));
  }

  Future<void> addEntry(TimesheetEntry entry) async {
    await _repo.addEntry(entry);
    await refreshEntries();
  }
}
