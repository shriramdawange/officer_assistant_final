// ============================================================
// models/user_profile.dart
// ============================================================

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String designation;
  final String department;
  final String? avatarUrl;
  final DateTime? createdAt; // nullable for guest/const usage

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.designation,
    required this.department,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Officer',
      designation: json['designation'] as String? ?? 'Government Officer',
      department: json['department'] as String? ?? 'Government of Maharashtra',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'designation': designation,
      'department': department,
      'avatar_url': avatarUrl,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? designation,
    String? department,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// First name only for greeting
  String get firstName => fullName.split(' ').first;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $fullName, designation: $designation)';
}
