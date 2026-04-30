enum UserRole {
  employee,
  admin;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.employee,
    );
  }
}

class Profile {
  final String id;
  final String fullName;
  final UserRole role;
  final int hourlyRateCents;
  final double overtimeMultiplier;

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.hourlyRateCents,
    required this.overtimeMultiplier,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      role: UserRole.fromString(json['role']),
      hourlyRateCents: json['hourly_rate_cents'] ?? 0,
      overtimeMultiplier: (json['overtime_multiplier'] as num?)?.toDouble() ?? 1.5,
    );
  }
}
