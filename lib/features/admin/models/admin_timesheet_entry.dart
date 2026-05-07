class AdminTimesheetEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime clockIn;
  final DateTime clockOut;
  final Duration worked;
  final Duration breaks;
  final int hourlyRateCents;
  final double overtimeMultiplier;

  AdminTimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    required this.clockOut,
    required this.worked,
    required this.breaks,
    required this.hourlyRateCents,
    required this.overtimeMultiplier,
  });
}
