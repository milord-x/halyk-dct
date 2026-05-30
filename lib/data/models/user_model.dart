class AppUser {
  final String id;
  final String organizationId;
  final String email;
  final String role;
  final String? fullName;
  final String organizationName;

  const AppUser({
    required this.id,
    required this.organizationId,
    required this.email,
    required this.role,
    this.fullName,
    required this.organizationName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        fullName: json['full_name'] as String?,
        organizationName: json['organization_name'] as String? ?? '',
      );
}
