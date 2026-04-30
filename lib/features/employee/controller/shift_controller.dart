import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_prefs_provider.dart';
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
  late SharedPreferences _prefs;

  static const _keyClockInAt = 'clock_in_at';
  static const _keyBreakStartedAt = 'break_started_at';
  static const _keyBreakElapsed = 'break_elapsed_ms';

  @override
  ShiftState build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    ref.onDispose(() {
      _timer?.cancel();
    });

    // Load persisted state
    final clockInMs = _prefs.getInt(_keyClockInAt);
    final breakStartedMs = _prefs.getInt(_keyBreakStartedAt);
    final breakElapsedMs = _prefs.getInt(_keyBreakElapsed) ?? 0;

    if (clockInMs != null) {
      final clockInAt = DateTime.fromMillisecondsSinceEpoch(clockInMs);
      final breakStartedAt = breakStartedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(breakStartedMs)
          : null;
      final breakElapsed = Duration(milliseconds: breakElapsedMs);

      // Schedule ticker start after build
      Future.microtask(() => _startTicker());

      return ShiftState(
        isClockedIn: true,
        clockInAt: clockInAt,
        elapsed: _calculateElapsed(clockInAt, breakElapsed, breakStartedAt),
        onBreak: breakStartedAt != null,
        breakStartedAt: breakStartedAt,
        breakElapsed: breakElapsed,
      );
    }

    return const ShiftState.initial();
  }

  void clockIn() {
    if (state.isClockedIn) return;

    final now = DateTime.now();
    _prefs.setInt(_keyClockInAt, now.millisecondsSinceEpoch);

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

      try {
        ref.read(timesheetControllerProvider.notifier).addEntry(
              TimesheetEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                clockIn: clockInAt,
                clockOut: clockOutAt,
                worked: worked,
                breaks: state.breakElapsed,
              ),
            );
      } catch (e) {
        // Log error and potentially notify user via a provider-based error state
        // For now, using debugPrint to satisfy lints
        debugPrint('Failed to add entry: $e');
      }
    }

    // Clear persistence
    _prefs.remove(_keyClockInAt);
    _prefs.remove(_keyBreakStartedAt);
    _prefs.remove(_keyBreakElapsed);

    state = const ShiftState.initial();
  }

  void startBreak() {
    if (!state.isClockedIn || state.onBreak) return;
    final now = DateTime.now();
    _prefs.setInt(_keyBreakStartedAt, now.millisecondsSinceEpoch);
    state = state.copyWith(onBreak: true, breakStartedAt: now);
  }

  void endBreak() {
    if (!state.isClockedIn || !state.onBreak) return;

    final started = state.breakStartedAt;
    final added =
        started == null ? Duration.zero : DateTime.now().difference(started);
    final totalBreak = state.breakElapsed + added;

    _prefs.remove(_keyBreakStartedAt);
    _prefs.setInt(_keyBreakElapsed, totalBreak.inMilliseconds);

    state = state.copyWith(
      onBreak: false,
      breakStartedAt: null,
      breakElapsed: totalBreak,
    );
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isClockedIn) return;

      state = state.copyWith(
        elapsed: _calculateElapsed(
          state.clockInAt!,
          state.breakElapsed,
          state.breakStartedAt,
        ),
      );
    });
  }

  Duration _calculateElapsed(
    DateTime clockInAt,
    Duration breakElapsed,
    DateTime? breakStartedAt,
  ) {
    final raw = DateTime.now().difference(clockInAt);
    final currentBreak = breakStartedAt != null
        ? DateTime.now().difference(breakStartedAt)
        : Duration.zero;

    final effective = raw - breakElapsed - currentBreak;
    return effective.isNegative ? Duration.zero : effective;
  }
}

