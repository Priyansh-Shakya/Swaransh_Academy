class User {
  const User({
    required this.email,
    this.userName,
    this.fcmToken,
    this.role,
    this.userId,
  });

  final String email;
  final String? role;
  final String? userName;
  final String? fcmToken;
  final String? userId;

  User copyWith({String? email, String? userName, String? fcmToken}) {
    return User(
      email: email ?? this.email,
      userName: userName ?? this.userName,
      fcmToken: fcmToken ?? fcmToken,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    email: json['email'] as String,
    userId: json['user_id'],
    role: json['role'] as String,
    userName: json['user_name'] as String?,
    fcmToken: json['fcmToken'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'user_name': userName,
    'role': role,
    'fcmToken': fcmToken,
  };
}
