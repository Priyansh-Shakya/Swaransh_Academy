class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.imageUrl,
  });

  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    displayName: json['display_name'] as String?,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'display_name': displayName,
    'image_url': imageUrl,
  };
}

class StudentProfileFull {
  const StudentProfileFull({
    required this.id,
    required this.name,
    required this.studentId,
    required this.department,
    required this.subject,
    required this.batch,
    this.userId,
    this.imageUrl,
    this.contact,
    this.email,
    this.dob,
    this.address,
  });

  final String id;
  final String name;
  final int studentId;
  final String department;
  final String subject;
  final String batch;
  final String? userId;
  final String? imageUrl;
  final String? contact;
  final String? email;
  final String? dob;
  final String? address;

  factory StudentProfileFull.fromJson(Map<String, dynamic> json) =>
      StudentProfileFull(
        id: json['id'] as String,
        name: json['name'] as String,
        studentId: json['student_id'] as int,
        department: json['department'] as String,
        subject: json['subject'] as String,
        batch: json['batch'] as String,
        userId: json['user_id'] as String?,
        imageUrl: json['image_url'] as String?,
        contact: json['contact'] as String?,
        email: json['email'] as String?,
        dob: json['dob'] as String?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'student_id': studentId,
    'department': department,
    'subject': subject,
    'batch': batch,
    'user_id': userId,
    'image_url': imageUrl,
    'contact': contact,
    'email': email,
    'dob': dob,
    'address': address,
  };
}
