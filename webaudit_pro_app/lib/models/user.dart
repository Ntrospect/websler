/// User model for WebAudit Pro
class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? companyName;
  final String? companyDetails;
  final String? avatarUrl;
  final String timezone; // User's preferred timezone (IANA format, e.g., 'America/New_York')
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.companyName,
    this.companyDetails,
    this.avatarUrl,
    this.timezone = 'UTC', // Default to UTC
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert to map for local database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'company_name': companyName,
      'company_details': companyDetails,
      'avatar_url': avatarUrl,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from map (from database or API)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      companyName: map['company_name'] as String?,
      companyDetails: map['company_details'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      timezone: map['timezone'] as String? ?? 'UTC', // Default to UTC if not set
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : map['created_at'] as DateTime,
      updatedAt: map['updated_at'] != null
          ? map['updated_at'] is String
              ? DateTime.parse(map['updated_at'] as String)
              : map['updated_at'] as DateTime
          : null,
    );
  }

  /// Copy with modifications
  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? companyName,
    String? companyDetails,
    String? avatarUrl,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      companyDetails: companyDetails ?? this.companyDetails,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, fullName: $fullName)';
  }
}
