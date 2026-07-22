class UserProfile {
  const UserProfile({
    required this.user_id,
    required this.email,
    required this.role,
    this.displayName,
    this.imageUrl,
  });

  final String user_id;
  final String email;
  final String role;
  final String? displayName;
  final String? imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    user_id: json['user_id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    displayName: json['display_name'] as String?,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'user_id': user_id,
    'email': email,
    'role': role,
    'display_name': displayName,
    'image_url': imageUrl,
  };
}
