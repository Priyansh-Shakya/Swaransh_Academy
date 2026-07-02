import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/widgets/student_fields_form.dart';
import '../data/admission_notifier.dart';
import '../domain/admission_form_state.dart';

class AdmissionFormScreen extends ConsumerStatefulWidget {
  const AdmissionFormScreen({super.key});

  @override
  ConsumerState<AdmissionFormScreen> createState() =>
      _AdmissionFormScreenState();
}

class _AdmissionFormScreenState extends ConsumerState<AdmissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late Map<String, String?> _dropdowns;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'fatherName': TextEditingController(),
      'dob': TextEditingController(),
      'contact': TextEditingController(),
      'email': TextEditingController(),
      'address': TextEditingController(),
      'religion': TextEditingController(),
      'caste': TextEditingController(),
      'subject': TextEditingController(),
      'startTime': TextEditingController(),
      'endTime': TextEditingController(),
      // not used in admission but StudentFieldsForm needs these keys
      'scholarNo': TextEditingController(),
      'dateOfJoining': TextEditingController(),
      'fees': TextEditingController(),
    };
    _dropdowns = {
      'gender': null,
      'educationQualification': null,
      'department': null,
      'admissionType': 'Regular',
      'learningMode': 'Offline',
      'batch': 'Morning',
      'feeType': 'Monthly',
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  /// Seed controllers from notifier state (handles pre-fill from course tap
  /// and restoring in-progress state if user navigated away mid-form).
  void _seedFromState(AdmissionFormState s) {
    if (_initialized) return;
    _initialized = true;

    _controllers['name']!.text = s.name;
    _controllers['fatherName']!.text = s.fatherName;
    _controllers['dob']!.text = s.dob;
    _controllers['contact']!.text = s.contact;
    _controllers['email']!.text = s.email;
    _controllers['address']!.text = s.address;
    _controllers['religion']!.text = s.religion;
    _controllers['caste']!.text = s.caste;
    _controllers['subject']!.text = s.prefillSubject ?? s.subject;
    _controllers['fees']!.text = s.fees?.toString() ?? '';
    _dropdowns['gender'] = s.gender;
    _dropdowns['educationQualification'] = s.educationQualification;
    _dropdowns['department'] = s.prefillDepartment ?? s.department;
    _dropdowns['admissionType'] = s.admissionType.isEmpty
        ? 'Regular'
        : s.admissionType;
    _dropdowns['learningMode'] = s.learningMode.isEmpty
        ? 'Offline'
        : s.learningMode;
    _dropdowns['batch'] = s.batch.isEmpty ? 'Morning' : s.batch;
    _dropdowns['feeType'] = s.feeType ?? 'Monthly';
  }

  void _saveToNotifier() {
    ref
        .read(admissionFormProvider.notifier)
        .update(
          (s) => s.copyWith(
            name: _controllers['name']!.text.trim(),
            fatherName: _controllers['fatherName']!.text.trim(),
            dob: _controllers['dob']!.text.trim(),
            contact: _controllers['contact']!.text.trim(),
            email: _controllers['email']!.text.trim(),
            address: _controllers['address']!.text.trim(),
            religion: _controllers['religion']!.text.trim(),
            caste: _controllers['caste']!.text.trim(),
            subject: _controllers['subject']!.text.trim(),
            startTime: _controllers['startTime']!.text.trim(),
            endTime: _controllers['endTime']!.text.trim(),
            gender: _dropdowns['gender'],
            educationQualification: _dropdowns['educationQualification'],
            department: _dropdowns['department'] ?? '',
            admissionType: _dropdowns['admissionType'] ?? 'Regular',
            learningMode: _dropdowns['learningMode'] ?? 'Offline',
            batch: _dropdowns['batch'] ?? 'Morning',
            fees: _controllers['fees']!.text.trim().isEmpty
                ? null
                : double.tryParse(_controllers['fees']!.text.trim()),
            feeType: _dropdowns['feeType'],
          ),
        );
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    _saveToNotifier();

    final role = ref.read(currentRoleProvider);
    if (role == UserRole.guest) {
      // Auth wall - guest must sign in before proceeding
      _showAuthWall();
      return;
    }
    context.push('/admission/terms');
  }

  void _showAuthWall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthWallSheet(
        onSignIn: () {
          Navigator.pop(context);
          // TODO: trigger Supabase Google Sign-In, then re-call _proceed()
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In coming soon')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(admissionFormProvider);
    _seedFromState(formState);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Admission Form'),
        backgroundColor: AppColors.ivory,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(current: 1, total: 3),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admission form feels more formal - a brief heading sets the tone
              Text(
                'Application for Admission',
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Please fill all required fields carefully. '
                'This information will be used to create your student record.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),

              StudentFieldsForm(
                controllers: _controllers,
                values: _dropdowns,
                editable: true,
                lockedFields: const {},
                // Show all sections including fees; hide admin-only fields
                // (scholarNo, dateOfJoining, religion, caste are in the admin
                //  section but we still collect religion/caste on admission -
                //  we'll show them via explicit fields below instead)
                visibleSections: const {
                  StudentFieldSection.identity,
                  StudentFieldSection.contact,
                  StudentFieldSection.course,
                },
                onDropdownChanged: (key, value) =>
                    setState(() => _dropdowns[key] = value),
              ),

              // Fees - admission form does collect this
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fees',
                style: AppTypography.titleLarge.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controllers['fees'],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\u20B9)',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _dropdowns['feeType'],
                      decoration: const InputDecoration(labelText: 'Fee Type'),
                      items: kFeeTypeOptions
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(o.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _dropdowns['feeType'] = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _proceed,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text('Continue to Terms & Conditions'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Step indicator ----

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final active = i < current;
          final isCurrent = i == current - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.gold
                    : isCurrent
                    ? AppColors.gold.withOpacity(0.4)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---- Auth wall sheet ----

class _AuthWallSheet extends StatelessWidget {
  const _AuthWallSheet({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40, color: AppColors.gold),
          const SizedBox(height: AppSpacing.md),
          Text('Sign in to continue', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your application is saved. Sign in with Google so we can link '
            'it to your account and track your application status.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back to form'),
          ),
        ],
      ),
    );
  }
}
