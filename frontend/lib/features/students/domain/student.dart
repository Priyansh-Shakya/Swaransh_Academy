/// Mirrors components.schemas.StudentFull in the OpenAPI contract. One
/// model for both StudentBasic and StudentFull - the backend decides which
/// fields are present in the JSON based on viewer role; nullable fields
/// here simply won't be populated when a StudentBasic payload arrives.
/// This keeps render logic in one place (a field's nullability/role-gating
/// decides whether it shows, not two parallel model classes).
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.admissionType,
    required this.learningMode,
    required this.department,
    required this.batch,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.userId,
    this.imageUrl,
    this.status,
    this.dob,
    this.fatherName,
    this.gender,
    this.educationQualification,
    this.contact,
    this.email,
    this.address,
    this.religion,
    this.caste,
    this.scholarNo,
    this.dateOfJoining,
    this.fees,
    this.feeType,
    this.feePaidTill,
  });

  // ---- StudentBasic fields (always present) ----
  final int id;
  final String name;
  final String admissionType;
  final String learningMode;
  final String department;
  final String batch;
  final String startTime;
  final String endTime;
  final String subject;

  // ---- StudentFull-only fields (null when viewer only has StudentBasic) ----
  final String? userId;
  final String? imageUrl;
  final String? status;
  final String? dob;
  final String? fatherName;
  final String? gender;
  final String? educationQualification;
  final String? contact;
  final String? email;
  final String? address;
  final String? religion;
  final String? caste;
  final String? scholarNo;
  final String? dateOfJoining;
  final double? fees;
  final String? feeType;
  final String? feePaidTill;

  /// True if this payload carries the admin/full shape, not just basic.
  /// Used to decide bottom-sheet (basic) vs full detail page (full) on tap.
  bool get isFullShape => status != null;

  Student copyWith({
    String? name,
    String? admissionType,
    String? learningMode,
    String? department,
    String? batch,
    String? startTime,
    String? endTime,
    String? subject,
    String? userId,
    String? imageUrl,
    String? status,
    String? dob,
    String? fatherName,
    String? gender,
    String? educationQualification,
    String? contact,
    String? email,
    String? address,
    String? religion,
    String? caste,
    String? scholarNo,
    String? dateOfJoining,
    double? fees,
    String? feeType,
    String? feePaidTill,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      admissionType: admissionType ?? this.admissionType,
      learningMode: learningMode ?? this.learningMode,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      dob: dob ?? this.dob,
      fatherName: fatherName ?? this.fatherName,
      gender: gender ?? this.gender,
      educationQualification: educationQualification ?? this.educationQualification,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      religion: religion ?? this.religion,
      caste: caste ?? this.caste,
      scholarNo: scholarNo ?? this.scholarNo,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      fees: fees ?? this.fees,
      feeType: feeType ?? this.feeType,
      feePaidTill: feePaidTill ?? this.feePaidTill,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as int,
        name: json['name'] as String,
        admissionType: json['admission_type'] as String,
        learningMode: json['learning_mode'] as String,
        department: json['department'] as String,
        batch: json['batch'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        subject: json['subject'] as String,
        userId: json['user_id'] as String?,
        imageUrl: json['image_url'] as String?,
        status: json['status'] as String?,
        dob: json['dob'] as String?,
        fatherName: json['father_name'] as String?,
        gender: json['gender'] as String?,
        educationQualification: json['education_qualification'] as String?,
        contact: json['contact'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        religion: json['religion'] as String?,
        caste: json['caste'] as String?,
        scholarNo: json['scholar_no'] as String?,
        dateOfJoining: json['date_of_joining'] as String?,
        fees: (json['fees'] as num?)?.toDouble(),
        feeType: json['fee_type'] as String?,
        feePaidTill: json['fee_paid_till'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'admission_type': admissionType,
        'learning_mode': learningMode,
        'department': department,
        'batch': batch,
        'start_time': startTime,
        'end_time': endTime,
        'subject': subject,
        'user_id': userId,
        'image_url': imageUrl,
        'status': status,
        'dob': dob,
        'father_name': fatherName,
        'gender': gender,
        'education_qualification': educationQualification,
        'contact': contact,
        'email': email,
        'address': address,
        'religion': religion,
        'caste': caste,
        'scholar_no': scholarNo,
        'date_of_joining': dateOfJoining,
        'fees': fees,
        'fee_type': feeType,
        'fee_paid_till': feePaidTill,
      };
}
