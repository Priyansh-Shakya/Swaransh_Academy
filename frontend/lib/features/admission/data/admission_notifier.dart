import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admission_form_record.dart';
import '../domain/admission_form_state.dart';
import 'admission_api_service.dart';

/// Holds in-progress form state across all three funnel screens.
class AdmissionFormNotifier extends Notifier<AdmissionFormState> {
  @override
  AdmissionFormState build() => const AdmissionFormState();

  void update(AdmissionFormState Function(AdmissionFormState) updater) {
    state = updater(state);
  }

  void prefill(String department, String subject, double? fees) {
    state = state.copyWith(
      department: department,
      subject: subject,
      prefillDepartment: department,
      prefillSubject: subject,
      fees: fees,
    );
  }

  void reset() => state = const AdmissionFormState();

  /// POST /admissionForm using the current in-memory state.
  /// No parameters — the notifier owns the data, not the caller.
  Future<int> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref
          .read(admissionApiServiceProvider)
          .postAdmissionForm(state.toJson());
      state = state.copyWith(isSubmitting: false, submittedFormId: result.id);
      return result.id;
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
    return ref.read(admissionApiServiceProvider).getAllAdmissionForms();
  }

  Future<void> approve(int formId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final f in current)
        if (f.id == formId) f.copyWith(status: 'Approved') else f,
    ]);
    try {
      await ref.read(admissionApiServiceProvider).approveForm(formId);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> decline(int formId) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final f in current)
        if (f.id == formId) f.copyWith(status: 'Declined') else f,
    ]);
    try {
      await ref.read(admissionApiServiceProvider).declineForm(formId);
    } catch (_) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final admissionFormsListProvider =
    AsyncNotifierProvider<
      AdmissionFormsListNotifier,
      List<AdmissionFormRecord>
    >(AdmissionFormsListNotifier.new);




// ---- Student: own submitted forms ----

class MyAdmissionFormsNotifier
    extends AsyncNotifier<List<AdmissionFormRecord>> {
  @override
  Future<List<AdmissionFormRecord>> build() async {
    return ref.read(admissionApiServiceProvider).getUserAdmissionForms();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(
        await ref.read(admissionApiServiceProvider).getUserAdmissionForms());
  }
}

final myAdmissionFormsProvider =
    AsyncNotifierProvider<MyAdmissionFormsNotifier, List<AdmissionFormRecord>>(
  MyAdmissionFormsNotifier.new,
);