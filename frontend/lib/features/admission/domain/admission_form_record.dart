/// Mirrors components.schemas.AdmissionForm in the OpenAPI contract.
/// Used for the admin's submitted-forms list view.
class AdmissionFormRecord {
  const AdmissionFormRecord({
    required this.id,
    required this.name,
    required this.department,
    required this.subject,
    required this.contact,
    required this.email,
    required this.status,
    required this.admissionType,
    required this.learningMode,
    required this.imageUrl,

    this.userId,
    this.fees,
    this.feeType,

    // New fields
    this.dob,
    this.fatherName,
    this.gender,
    this.educationQualification,
    this.address,
    this.religion,
    this.caste,
    this.batch,
    this.startTime,
    this.endTime,
  });

  final int id;
  final String imageUrl;
  final String name;
  final String department;
  final String subject;
  final String contact;
  final String email;
  final String status; // Pending | Approved | Declined
  final String admissionType;
  final String learningMode;

  final String? userId;
  final double? fees;
  final String? feeType;

  // Additional backend fields
  final DateTime? dob;
  final String? fatherName;
  final String? gender;
  final String? educationQualification;
  final String? address;
  final String? religion;
  final String? caste;
  final String? batch;
  final String? startTime;
  final String? endTime;

  factory AdmissionFormRecord.fromJson(Map<String, dynamic> json) =>
      AdmissionFormRecord(
        id: json['id'] as int,
        imageUrl: (json['image_url'] ?? '') as String,
        name: json['name'] as String,
        department: json['department'] as String,
        subject: json['subject'] as String,
        contact: json['contact'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
        admissionType: json['admission_type'] as String,
        learningMode: json['learning_mode'] as String,

        userId: json['user_id'] as String?,
        fees: (json['fees'] as num?)?.toDouble(),
        feeType: json['fee_type'] as String?,

        // New fields
        dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
        fatherName: json['father_name'] as String?,
        gender: json['gender'] as String?,
        educationQualification: json['education_qualification'] as String?,
        address: json['address'] as String?,
        religion: json['religion'] as String?,
        caste: json['caste'] as String?,
        batch: json['batch'] as String?,
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
      );

  AdmissionFormRecord copyWith({String? status}) => AdmissionFormRecord(
    id: id,
    imageUrl: imageUrl,
    name: name,
    department: department,
    subject: subject,
    contact: contact,
    email: email,
    status: status ?? this.status,
    admissionType: admissionType,
    learningMode: learningMode,

    userId: userId,
    fees: fees,
    feeType: feeType,

    dob: dob,
    fatherName: fatherName,
    gender: gender,
    educationQualification: educationQualification,
    address: address,
    religion: religion,
    caste: caste,
    batch: batch,
    startTime: startTime,
    endTime: endTime,
  );
}
