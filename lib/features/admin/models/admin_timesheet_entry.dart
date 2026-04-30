class AdminTimesheetEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime clockIn;
  final DateTime clockOut;
  final Duration worked;
  final Duration breaks;

  AdminTimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    required this.clockOut,
    required this.worked,
    required this.breaks,
  });
}