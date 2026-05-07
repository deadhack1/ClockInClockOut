class PayrollRecord {
  final String id;
  final String payPeriodId;
  final String employeeId;
  final int regularMinutes;
  final int overtimeMinutes;
  final int grossPayCents;
  final DateTime generatedAt;

  PayrollRecord({
    required this.id,
    required this.payPeriodId,
    required this.employeeId,
    required this.regularMinutes,
    required this.overtimeMinutes,
    required this.grossPayCents,
    required this.generatedAt,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'],
      payPeriodId: json['pay_period_id'],
      employeeId: json['employee_id'],
      regularMinutes: json['regular_minutes'] ?? 0,
      overtimeMinutes: json['overtime_minutes'] ?? 0,
      grossPayCents: json['gross_pay_cents'] ?? 0,
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pay_period_id': payPeriodId,
      'employee_id': employeeId,
      'regular_minutes': regularMinutes,
      'overtime_minutes': overtimeMinutes,
      'gross_pay_cents': grossPayCents,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}
