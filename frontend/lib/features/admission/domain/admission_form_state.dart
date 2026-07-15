/// Holds the in-progress admission form data across all three funnel
/// screens (form → T&C → payment). Separate from Student/AdmissionForm
/// contract schemas intentionally - this is UI state, not a DB record.
class AdmissionFormState {
  const AdmissionFormState({
    // Basic (StudentBasic fields)
    this.name = '',
    this.department = '',
    this.subject = '',
    this.admissionType = '',
    this.learningMode = '',
    this.batch = '',
    this.startTime = '',
    this.endTime = '',
    // Personal
    this.fatherName = '',
    this.dob = '',
    this.gender,
    this.educationQualification,
    // Contact
    this.contact = '',
    this.email = '',
    this.address = '',
    // Optional
    this.religion = '',
    this.caste = '',
    // Fees
    this.fees,
    this.feeType,
    // Pre-fill source
    this.prefillDepartment,
    this.prefillSubject,
    // Submission
    this.isSubmitting = false,
    this.submittedFormId,
  });

  final String name;
  final String department;
  final String subject;
  final String admissionType;
  final String learningMode;
  final String batch;
  final String startTime;
  final String endTime;
  final String fatherName;
  final String dob;
  final String? gender;
  final String? educationQualification;
  final String contact;
  final String email;
  final String address;
  final String religion;
  final String caste;
  final double? fees;
  final String? feeType;
  final String? prefillDepartment;
  final String? prefillSubject;
  final bool isSubmitting;
  final int? submittedFormId; // set after successful POST /admissionForm

  AdmissionFormState copyWith({
    String? name,
    String? department,
    String? subject,
    String? admissionType,
    String? learningMode,
    String? batch,
    String? startTime,
    String? endTime,
    String? fatherName,
    String? dob,
    String? gender,
    String? educationQualification,
    String? contact,
    String? email,
    String? address,
    String? religion,
    String? caste,
    double? fees,
    String? feeType,
    String? prefillDepartment,
    String? prefillSubject,
    bool? isSubmitting,
    int? submittedFormId,
  }) {
    return AdmissionFormState(
      name: name ?? this.name,
      department: department ?? this.department,
      subject: subject ?? this.subject,
      admissionType: admissionType ?? this.admissionType,
      learningMode: learningMode ?? this.learningMode,
      batch: batch ?? this.batch,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      fatherName: fatherName ?? this.fatherName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      educationQualification:
          educationQualification ?? this.educationQualification,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      address: address ?? this.address,
      religion: religion ?? this.religion,
      caste: caste ?? this.caste,
      fees: fees ?? this.fees,
      feeType: feeType ?? this.feeType,
      prefillDepartment: prefillDepartment ?? this.prefillDepartment,
      prefillSubject: prefillSubject ?? this.prefillSubject,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedFormId: submittedFormId ?? this.submittedFormId,
    );
  }

  bool get isEmpty => name.isEmpty && contact.isEmpty && email.isEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'father_name': fatherName,
    'dob': dob.isEmpty ? null : dob,
    'gender': gender,
    'education_qualification': educationQualification,
    'contact': contact,
    'email': email,
    'address': address,
    'religion': religion.isEmpty ? null : religion,
    'caste': caste.isEmpty ? null : caste,
    'department': department,
    'subject': subject,
    'admission_type': admissionType,
    'learning_mode': learningMode,
    'batch': batch,
    'start_time': startTime,
    'end_time': endTime,
    'fees': fees,
    'fee_type': feeType,
  };
}
