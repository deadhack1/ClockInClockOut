import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

final activeShiftsProvider = StreamProvider<Map<String, DateTime>>((ref) {
  final repo = ref.watch(timesheetRepositoryProvider);
  
  return (() async* {
    yield await repo.fetchActiveShifts();
    yield* Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => repo.fetchActiveShifts());
  })();
});

// A simpler one for immediate use
final activeShiftsFutureProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  return ref.watch(timesheetRepositoryProvider).fetchActiveShifts();
});
