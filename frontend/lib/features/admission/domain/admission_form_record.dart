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
    this.userId,
    this.fees,
    this.feeType,
  });

  final int id;
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

  factory AdmissionFormRecord.fromJson(Map<String, dynamic> json) =>
      AdmissionFormRecord(
        id: json['id'] as int,
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
      );

  AdmissionFormRecord copyWith({String? status}) => AdmissionFormRecord(
        id: id,
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
      );
}
