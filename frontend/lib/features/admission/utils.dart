class ValidateForm {
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
  final String gender;
  final String educationQualification;
  final String contact;
  final String email;
  final String address;
  final String? religion;
  final String? caste;
  final double fees;
  final String feeType;
  final String prefillDepartment;
  final String prefillSubject;
  final String? image_url;

  ValidateForm({
    required this.name,
    required this.department,
    required this.subject,
    required this.admissionType,
    required this.learningMode,
    required this.batch,
    required this.startTime,
    required this.endTime,
    required this.fatherName,
    required this.dob,
    required this.gender,
    required this.educationQualification,
    required this.contact,
    required this.email,
    required this.address,
    required this.fees,
    required this.feeType,
    required this.prefillDepartment,
    required this.prefillSubject,
    this.religion,
    this.caste,
    this.image_url,
  });
}

class ValidateFormValidator {
  static String? validate(ValidateForm form) {
    // Required fields
    if (_isEmpty(form.name)) {
      return 'Please enter the student name.';
    }

    if (_isEmpty(form.department)) {
      return 'Please select a department.';
    }

    if (_isEmpty(form.subject)) {
      return 'Please select a subject.';
    }

    if (_isEmpty(form.admissionType)) {
      return 'Please select an admission type.';
    }

    if (_isEmpty(form.learningMode)) {
      return 'Please select a learning mode.';
    }

    if (_isEmpty(form.batch)) {
      return 'Please select a batch.';
    }

    if (_isEmpty(form.startTime)) {
      return 'Please select the class start time.';
    }

    if (_isEmpty(form.endTime)) {
      return 'Please select the class end time.';
    }

    if (_isEmpty(form.fatherName)) {
      return 'Please enter the father\'s name.';
    }

    if (_isEmpty(form.dob)) {
      return 'Please select the date of birth.';
    }

    if (_isEmpty(form.gender)) {
      return 'Please select a gender.';
    }

    if (_isEmpty(form.educationQualification)) {
      return 'Please enter the education qualification.';
    }

    if (_isEmpty(form.contact)) {
      return 'Please enter a contact number.';
    }

    if (!_isValidPhone(form.contact)) {
      return 'Contact number must contain exactly 10 digits.';
    }

    if (_isEmpty(form.email)) {
      return 'Please enter an email address.';
    }

    if (!_isValidEmail(form.email)) {
      return 'Please enter a valid email address.';
    }

    if (_isEmpty(form.address)) {
      return 'Please enter the address.';
    }

    if (_isEmpty(form.feeType)) {
      return 'Please select a fee type.';
    }

    if (form.fees <= 0) {
      return 'Fee amount must be greater than zero.';
    }

    if (_isEmpty(form.prefillDepartment)) {
      return 'Prefill department is missing.';
    }

    if (_isEmpty(form.prefillSubject)) {
      return 'Prefill subject is missing.';
    }

    return null;
  }

  static bool _isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  static bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }
}
