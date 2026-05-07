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
  final String? organizationId;
  final int hourlyRateCents;
  final double overtimeMultiplier;
  final bool isActive;
  final DateTime createdAt;
  final String? email;
  final String? password; // Simple password for kiosk login

  Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.organizationId,
    required this.hourlyRateCents,
    required this.overtimeMultiplier,
    required this.isActive,
    required this.createdAt,
    this.email,
    this.password,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      role: UserRole.fromString(json['role']),
      organizationId: json['organization_id'],
      hourlyRateCents: json['hourly_rate_cents'] ?? 0,
      overtimeMultiplier: (json['overtime_multiplier'] as num?)?.toDouble() ?? 1.5,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      email: json['email'],
      password: json['encrypted_punch_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role.name,
      'organization_id': organizationId,
      'hourly_rate_cents': hourlyRateCents,
      'overtime_multiplier': overtimeMultiplier,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'email': email,
      'password': password,
    };
  }
}
