import 'package:clock_in_clock_out/features/employee/repositories/timesheet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/shared_prefs_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../repositories/sync_repository.dart';

final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref){
  final client=ref.watch(supabaseProvider);
  return TimesheetRepository(client);
});

final syncRepositoryProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final repo = ref.watch(timesheetRepositoryProvider);
  final client = ref.watch(supabaseProvider);
  return SyncRepository(
    prefs: prefs,
    timesheetRepo: repo,
    supabase: client,
  );
});
