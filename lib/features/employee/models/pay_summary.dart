class PaySummary {
  final Duration totalWorked;
  final Duration overtime;
  final double estimatedPay;

  const PaySummary({
    required this.totalWorked,
    required this.overtime,
    required this.estimatedPay,
  });
}