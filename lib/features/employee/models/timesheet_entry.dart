class TimesheetEntry {
  final String id;
  final DateTime clockIn;
  final DateTime clockOut;
  final Duration worked;
  final Duration breaks;

  const TimesheetEntry({
    required this.id,
    required this.clockIn,
    required this.clockOut,
    required this.worked,
    required this.breaks,
  });
}