import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admission_form_record.dart';
import '../domain/admission_form_state.dart';

/// Holds in-progress form state across all three funnel screens.
/// Lives at app root (never disposed mid-flow) so state survives
/// tab switches and route pushes within a session.
class AdmissionFormNotifier extends Notifier<AdmissionFormState> {
  @override
  AdmissionFormState build() => const AdmissionFormState();

  void update(AdmissionFormState Function(AdmissionFormState) updater) {
    state = updater(state);
  }

  void prefill(String department, String subject) {
    state = state.copyWith(
      department: department,
      subject: subject,
      prefillDepartment: department,
      prefillSubject: subject,
    );
  }

  void reset() => state = const AdmissionFormState();

  /// MOCK submit - replace body with real Dio POST /admissionForm call.
  /// Returns the mock-assigned form id on success.
  Future<int> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // simulate network
      const mockId = 42;
      state = state.copyWith(isSubmitting: false, submittedFormId: mockId);
      return mockId;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final admissionFormProvider =
    NotifierProvider<AdmissionFormNotifier, AdmissionFormState>(
  AdmissionFormNotifier.new,
);

// ---- Admin: submitted forms list ----

class AdmissionFormsListNotifier
    extends AsyncNotifier<List<AdmissionFormRecord>> {
  @override
  Future<List<AdmissionFormRecord>> build() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.of(_mockForms);
  }

  /// MOCK approve - replace with Dio POST /admissionForm/{id}/approved
  Future<void> approve(int formId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final f in current)
        if (f.id == formId) f.copyWith(status: 'Approved') else f,
    ]);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  /// MOCK decline - replace with Dio POST /admissionForm/{id}/declined
  Future<void> decline(int formId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final f in current)
        if (f.id == formId) f.copyWith(status: 'Declined') else f,
    ]);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final admissionFormsListProvider =
    AsyncNotifierProvider<AdmissionFormsListNotifier, List<AdmissionFormRecord>>(
  AdmissionFormsListNotifier.new,
);

final List<AdmissionFormRecord> _mockForms = [
  const AdmissionFormRecord(
    id: 1,
    name: 'Riya Verma',
    department: 'Dance',
    subject: 'Bharatnatyam',
    contact: '9876501234',
    email: 'riya.verma@gmail.com',
    status: 'Pending',
    admissionType: 'Regular',
    learningMode: 'Offline',
    fees: 2200,
    feeType: 'Monthly',
  ),
  const AdmissionFormRecord(
    id: 2,
    name: 'Arjun Mehta',
    department: 'Music',
    subject: 'Flute',
    contact: '9876509876',
    email: 'arjun.mehta@gmail.com',
    status: 'Pending',
    admissionType: 'Regular',
    learningMode: 'Hybrid',
    fees: 2500,
    feeType: 'Monthly',
  ),
  const AdmissionFormRecord(
    id: 3,
    name: 'Sneha Joshi',
    department: 'Acting',
    subject: 'Acting',
    contact: '9876505555',
    email: 'sneha.joshi@gmail.com',
    status: 'Approved',
    admissionType: 'Summer_Camp',
    learningMode: 'Offline',
    fees: 1500,
    feeType: 'Quarterly',
  ),
];
