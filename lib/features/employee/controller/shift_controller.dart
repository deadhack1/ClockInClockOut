import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timesheet_entry.dart';
import 'timesheet_controller.dart';

class ShiftState {
  final bool isClockedIn;
  final DateTime? clockInAt;
  final Duration elapsed;
  final bool onBreak;
  final DateTime? breakStartedAt;
  final Duration breakElapsed;

  const ShiftState({
    required this.isClockedIn,
    required this.clockInAt,
    required this.elapsed,
    required this.onBreak,
    required this.breakStartedAt,
    required this.breakElapsed,
  });

  const ShiftState.initial()
      : isClockedIn = false,
        clockInAt = null,
        elapsed = Duration.zero,
        onBreak = false,
        breakStartedAt = null,
        breakElapsed = Duration.zero;

  ShiftState copyWith({
    bool? isClockedIn,
    DateTime? clockInAt,
    Duration? elapsed,
    bool? onBreak,
    DateTime? breakStartedAt,
    Duration? breakElapsed,
  }) {
    return ShiftState(
      isClockedIn: isClockedIn ?? this.isClockedIn,
      clockInAt: clockInAt ?? this.clockInAt,
      elapsed: elapsed ?? this.elapsed,
      onBreak: onBreak ?? this.onBreak,
      breakStartedAt: breakStartedAt ?? this.breakStartedAt,
      breakElapsed: breakElapsed ?? this.breakElapsed,
    );
  }
}

final shiftControllerProvider =
NotifierProvider<ShiftController, ShiftState>(ShiftController.new);

class ShiftController extends Notifier<ShiftState> {
  Timer? _timer;

  @override
  ShiftState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const ShiftState.initial();
  }

  void clockIn() {
    if (state.isClockedIn) return;

    final now = DateTime.now();
    state = state.copyWith(
      isClockedIn: true,
      clockInAt: now,
      elapsed: Duration.zero,
      onBreak: false,
      breakStartedAt: null,
      breakElapsed: Duration.zero,
    );

    _startTicker();
  }

  void clockOut() {
    if (!state.isClockedIn) return;

    if (state.onBreak) {
      endBreak();
    }

    _timer?.cancel();
    _timer = null;

    final clockOutAt = DateTime.now();
    final clockInAt = state.clockInAt;

    if (clockInAt != null) {
      final worked = state.elapsed;

      ref.read(timesheetControllerProvider.notifier).addEntry(
        TimesheetEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          clockIn: clockInAt,
          clockOut: clockOutAt,
          worked: worked,
          breaks: state.breakElapsed,
        ),
      );
    }

    state = state.copyWith(
      isClockedIn: false,
      clockInAt: null,
      elapsed: Duration.zero,
      onBreak: false,
      breakStartedAt: null,
      breakElapsed: Duration.zero,
    );
  }

  void startBreak() {
    if (!state.isClockedIn || state.onBreak) return;
    state = state.copyWith(onBreak: true, breakStartedAt: DateTime.now());
  }

  void endBreak() {
    if (!state.isClockedIn || !state.onBreak) return;

    final started = state.breakStartedAt;
    final added = started == null ? Duration.zero : DateTime.now().difference(started);

    state = state.copyWith(
      onBreak: false,
      breakStartedAt: null,
      breakElapsed: state.breakElapsed + added,
    );
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isClockedIn) return;

      final start = state.clockInAt;
      if (start == null) return;

      final raw = DateTime.now().difference(start);
      final effective = raw - state.breakElapsed - (state.onBreak && state.breakStartedAt != null
          ? DateTime.now().difference(state.breakStartedAt!)
          : Duration.zero);

      state = state.copyWith(elapsed: effective.isNegative ? Duration.zero : effective);
    });
  }
}
