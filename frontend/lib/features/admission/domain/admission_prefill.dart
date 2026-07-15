import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdmissionPrefill {
  const AdmissionPrefill({
    required this.department,
    required this.subject,
    required this.fees,
   
  });
  final String department;
  final String subject;
  final double fees;
  
}

/// Set by CourseDetailPage's "Apply Now" button, read (and cleared) by the
/// Admission feature once it builds its real form. Nullable - null means
/// "no pre-fill, generic apply" (e.g. user came from the Admission tab
/// directly, not via a course).
class AdmissionPrefillNotifier extends Notifier<AdmissionPrefill?> {
  @override
  AdmissionPrefill? build() => null;

  void set(AdmissionPrefill prefill) => state = prefill;

  void clear() => state = null;
}

final admissionPrefillProvider =
    NotifierProvider<AdmissionPrefillNotifier, AdmissionPrefill?>(
      AdmissionPrefillNotifier.new,
    );
