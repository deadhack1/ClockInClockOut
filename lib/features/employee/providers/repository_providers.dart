
import 'package:clock_in_clock_out/features/employee/repositories/timesheet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provide.dart';

final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref){
  final client=ref.watch(supabaseProvider);
  return TimesheetRepository(client);
});