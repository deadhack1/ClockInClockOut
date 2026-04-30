class AdminPayrollSummary {
  final String employeeName;
  final Duration totalWorked;
  final Duration overtime;
  final double totalPay;

  AdminPayrollSummary({
    required this.employeeName,
    required this.totalWorked,
    required this.overtime,
    required this.totalPay,
  });
}