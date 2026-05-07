class TimesheetEntry {
  final String id;
  final String employeeId;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String status;
  final String? notes;
  final String? editedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration worked;
  final Duration breaks;

  const TimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.clockIn,
    this.clockOut,
    required this.status,
    this.notes,
    this.editedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.worked,
    required this.breaks,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json, {Duration totalBreaks = Duration.zero}) {
    final clockIn = DateTime.parse(json['clock_in']);
    final clockOut = json['clock_out'] != null ? DateTime.parse(json['clock_out']) : null;
    
    // Use stored breaks if available (from offline storage)
    final storedBreaks = json['breaks_ms'] != null 
        ? Duration(milliseconds: json['breaks_ms']) 
        : totalBreaks;

    // Calculate worked time: (Out - In) - Breaks
    Duration worked = Duration.zero;
    if (clockOut != null) {
      worked = clockOut.difference(clockIn) - storedBreaks;
    } else {
      worked = DateTime.now().difference(clockIn) - storedBreaks;
    }

    return TimesheetEntry(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id'],
      clockIn: clockIn,
      clockOut: clockOut,
      status: json['status'] ?? 'completed',
      notes: json['notes'],
      editedBy: json['edited_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      worked: worked,
      breaks: storedBreaks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'status': status,
      'notes': notes,
      'edited_by': editedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'breaks_ms': breaks.inMilliseconds,
    };
  }
}
