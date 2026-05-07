class PayPeriod {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  PayPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory PayPeriod.fromJson(Map<String, dynamic> json) {
    return PayPeriod(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
