import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/widgets/student_fields_form.dart';
import '../data/admission_notifier.dart';
import '../domain/admission_form_state.dart';

// ---- Required field keys (shown with * in label) ----
const _requiredFields = {
  'name',
  'fatherName',
  'dob',
  'gender',
  'educationQualification',
  'contact',
  'email',
  'address',
  'department',
  'subject',
  'admissionType',
  'learningMode',
  'batch',
  'startTime',
  'endTime',
  'fees',
  'feeType',
};

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

  // Separate controllers for fields outside StudentFieldsForm
  late final TextEditingController _religionCtrl;
  late final TextEditingController _casteCtrl;
  late final TextEditingController _feesCtrl;

  // Add at top of _AdmissionFormScreenState:
  String? _imageUrl;

  late final ImagePickerController _photoController;

  @override
  void initState() {
    super.initState();
    _religionCtrl = TextEditingController();
    _casteCtrl = TextEditingController();
    _feesCtrl = TextEditingController();

    _controllers = {
      'name': TextEditingController(),
      'fatherName': TextEditingController(),
      'dob': TextEditingController(),
      'contact': TextEditingController(),
      'email': TextEditingController(),
      'address': TextEditingController(),
      'subject': TextEditingController(),
      'startTime': TextEditingController(),
      'endTime': TextEditingController(),
      // Unused in admission but StudentFieldsForm may reference these
      'scholarNo': TextEditingController(),
      'dateOfJoining': TextEditingController(),
      'fees': _feesCtrl,
      'religion': _religionCtrl,
      'caste': _casteCtrl,
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

    _photoController = ImagePickerController(
      initialUrl: ref.read(admissionFormProvider).imageUrl.isEmpty
          ? null
          : ref.read(admissionFormProvider).imageUrl,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    // religion/caste/fees are inside _controllers so already disposed above
    super.dispose();
  }

  void _seedFromState(AdmissionFormState s) {
    if (_initialized) return;
    _initialized = true;

    _controllers['name']!.text = s.name;
    _controllers['fatherName']!.text = s.fatherName;
    _controllers['dob']!.text = s.dob;
    _controllers['contact']!.text = s.contact;
    _controllers['email']!.text = s.email;
    _controllers['address']!.text = s.address;
    _controllers['subject']!.text = s.prefillSubject ?? s.subject;
    _controllers['startTime']!.text = s.startTime;
    _controllers['endTime']!.text = s.endTime;
    _religionCtrl.text = s.religion;
    _casteCtrl.text = s.caste;
    if (s.fees != null) _feesCtrl.text = s.fees!.toStringAsFixed(0);

    _dropdowns['gender'] = s.gender;
    _dropdowns['educationQualification'] = s.educationQualification;
    _dropdowns['department'] = (s.prefillDepartment?.isNotEmpty == true)
        ? s.prefillDepartment
        : s.department;
    _dropdowns['admissionType'] = s.admissionType.isEmpty
        ? 'Regular'
        : s.admissionType;
    _dropdowns['learningMode'] = s.learningMode.isEmpty
        ? 'Offline'
        : s.learningMode;
    _dropdowns['batch'] = s.batch.isEmpty ? 'Morning' : s.batch;
    _dropdowns['feeType'] = s.feeType ?? 'Monthly';
  }

  void _saveToNotifier() async {
    setState(() => _proceeding = true);
    try {
      final photoUrl = await _photoController.upload(
        ref: ref,
        bucket: StorageBucket.admissionPhotos,
        pathBuilder: () => StoragePath.admissionPhoto(
          ref.read(admissionFormProvider).draftId,
          'photo.jpg',
        ),
        isPrivate: false,
      );
      _imageUrl = photoUrl;

      debugPrint(
        "Photo URL Available, Proceeding to saving to notifier.\nURL:$_imageUrl",
      );
    } catch (e) {
      if (mounted) {
        debugPrint("Error uploading photo: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) setState(() => _proceeding = false);
      return;
    }
    debugPrint("Saving to notifier...");
    ref
        .read(admissionFormProvider.notifier)
        .update(
          (s) => s.copyWith(
            imageUrl: _imageUrl,
            name: _controllers['name']!.text.trim(),
            fatherName: _controllers['fatherName']!.text.trim(),
            dob: _controllers['dob']!.text.trim(),
            contact: _controllers['contact']!.text.trim(),
            email: _controllers['email']!.text.trim(),
            address: _controllers['address']!.text.trim(),
            subject: _controllers['subject']!.text.trim(),
            startTime: _controllers['startTime']!.text.trim(),
            endTime: _controllers['endTime']!.text.trim(),
            religion: _religionCtrl.text.trim(),
            caste: _casteCtrl.text.trim(),
            fees: double.tryParse(_feesCtrl.text.trim()),
            gender: _dropdowns['gender'],
            educationQualification: _dropdowns['educationQualification'],
            department: _dropdowns['department'] ?? '',
            admissionType: _dropdowns['admissionType'] ?? 'Regular',
            learningMode: _dropdowns['learningMode'] ?? 'Offline',
            batch: _dropdowns['batch'] ?? 'Morning',
            feeType: _dropdowns['feeType'],
          ),
        );
  }

  String? _validate() {
    final name = _controllers['name']!.text.trim();
    final fatherName = _controllers['fatherName']!.text.trim();
    final dob = _controllers['dob']!.text.trim();
    final contact = _controllers['contact']!.text.trim();
    final email = _controllers['email']!.text.trim();
    final address = _controllers['address']!.text.trim();
    final subject = _controllers['subject']!.text.trim();
    final startTime = _controllers['startTime']!.text.trim();
    final endTime = _controllers['endTime']!.text.trim();
    final feesText = _feesCtrl.text.trim();
    final fees = double.tryParse(feesText);

    if (name.isEmpty) return 'Please enter the student name.';
    if (fatherName.isEmpty) return 'Please enter the father\'s name.';
    if (dob.isEmpty) return 'Please enter the date of birth.';
    if (_dropdowns['gender'] == null) return 'Please select a gender.';
    if (_dropdowns['educationQualification'] == null)
      return 'Please select education qualification.';
    if (contact.isEmpty) return 'Please enter a contact number.';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(contact))
      return 'Contact number must be exactly 10 digits.';
    if (email.isEmpty) return 'Please enter an email address.';
    if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email))
      return 'Please enter a valid email address.';
    if (address.isEmpty) return 'Please enter the address.';
    if ((_dropdowns['department'] ?? '').isEmpty)
      return 'Please select a department.';
    if (subject.isEmpty) return 'Please enter the subject.';
    if ((_dropdowns['admissionType'] ?? '').isEmpty)
      return 'Please select an admission type.';
    if ((_dropdowns['learningMode'] ?? '').isEmpty)
      return 'Please select a learning mode.';
    if ((_dropdowns['batch'] ?? '').isEmpty) return 'Please select a batch.';
    if (startTime.isEmpty) return 'Please enter class start time.';
    if (endTime.isEmpty) return 'Please enter class end time.';
    if (feesText.isEmpty) return 'Please enter the fee amount.';
    if (fees == null || fees <= 0)
      return 'Fee amount must be greater than zero.';
    if ((_dropdowns['feeType'] ?? '').isEmpty)
      return 'Please select a fee type.';
    return null;
  }

  bool _proceeding = false;

  Future<void> _proceed() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isSignedIn = ref.read(isSignedInProvider);
    if (!isSignedIn) {
      _saveToNotifier(); // save text fields so nothing's lost
      _showAuthWall();
      return;
    } else {
      _saveToNotifier(); 
      context.push('/admission/terms');
    }
  }

  // In admission_form_screen.dart, replace _showAuthWall():
  void _showAuthWall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthWallSheet(
        onSignIn: () {
          Navigator.pop(context);
          final router = GoRouter.of(context); // capture before pop
          router.push(
            '/auth',
            extra: () {
              router.push('/admission/terms');
            },
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
          preferredSize: const Size.fromHeight(20),
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
              Text(
                'Application for Admission',
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Fields marked with * are required.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Identity + Contact + Course via shared widget
              StudentFieldsForm(
                controllers: _controllers,
                values: _dropdowns,
                isCreate: false,
                editable: true,
                lockedFields: const {},
                requiredFields: _requiredFields,
                onDropdownChanged: (key, value) =>
                    setState(() => _dropdowns[key] = value),
                visibleSections: const {
                  StudentFieldSection.identity,
                  StudentFieldSection.contact,
                  StudentFieldSection.course,
                },
                imagePickerController: _photoController,
              ),

              // Optional fields section
              const _SectionHeader('Additional Information (Optional)'),
              TextFormField(
                controller: _religionCtrl,
                decoration: const InputDecoration(labelText: 'Religion'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _casteCtrl,
                decoration: const InputDecoration(labelText: 'Caste'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Fees section
              const _SectionHeader('Fees'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _feesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\u20B9) *',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _dropdowns['feeType'],
                      decoration: const InputDecoration(
                        labelText: 'Fee Type *',
                      ),
                      items: kFeeTypeOptions
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                o.replaceAll('_', ' '),
                                style: AppTypography.bodyMedium,
                              ),
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

// ---- Helpers ----

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTypography.titleLarge.copyWith(color: AppColors.gold),
      ),
    );
  }
}

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
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.gold : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

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
