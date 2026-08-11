import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/widgets/student_fields_form.dart';

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

class StudentCreatePage extends ConsumerStatefulWidget {
  const StudentCreatePage({super.key});

  @override
  ConsumerState<StudentCreatePage> createState() => _StudentCreatePageState();
}

class _StudentCreatePageState extends ConsumerState<StudentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'fatherName': TextEditingController(),
    'dob': TextEditingController(),
    'contact': TextEditingController(),
    'email': TextEditingController(),
    'address': TextEditingController(),
    'scholarNo': TextEditingController(),
    'dateOfJoining': TextEditingController(),
    'fees': TextEditingController(),
    'religion': TextEditingController(),
    'caste': TextEditingController(),
    'subject': TextEditingController(),
    'startTime': TextEditingController(),
    'endTime': TextEditingController(),
  };

  final _dropdowns = <String, String?>{
    'gender': null,
    'educationQualification': null,
    'department': 'Music',
    'admissionType': 'Regular',
    'learningMode': 'Offline',
    'batch': 'Morning',
    'feeType': 'Monthly',
  };

  //* Image field — created once, here, not in build().
  late final ImagePickerController _photoController;

  @override
  void initState() {
    super.initState();
    _photoController = ImagePickerController(); // no existing photo on create
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = ref.read(supabaseProvider).auth.currentSession?.user.id;
    String? imageUrl;

    if (userId != null) {
      try {
        imageUrl = await _photoController.upload(
          ref: ref,
          bucket: StorageBucket.studentPhotos,
          pathBuilder: () => StoragePath.studentPhoto(userId, 'photo.jpg'),
        );
        debugPrint("Photo URL available: $imageUrl");
      } catch (e) {
        debugPrint("Error on image upload, Student Create: $e");
        // photo upload failed — proceeding without a photo rather than
        // blocking the whole student creation. Reconsider if a photo
        // should be mandatory for your flow.
      }
    }

    final draft = CreateStudent(
      imageUrl: imageUrl,
      name: _controllers['name']!.text.trim(),
      admissionType: _dropdowns['admissionType'] ?? 'Regular',
      learningMode: _dropdowns['learningMode'] ?? 'Offline',
      department: _dropdowns['department'] ?? 'Music',
      batch: _dropdowns['batch'] ?? 'Morning',
      startTime: _controllers['startTime']!.text.trim(),
      endTime: _controllers['endTime']!.text.trim(),
      subject: _controllers['subject']!.text.trim(),
      status: 'active',
      fatherName: _controllers['fatherName']!.text.trim(),
      dob: _controllers['dob']!.text.trim(),
      gender: _dropdowns['gender']!,
      educationQualification: _dropdowns['educationQualification']!,
      contact: _controllers['contact']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      address: _controllers['address']!.text.trim(),
      dateOfJoining: _controllers['dateOfJoining']!.text.trim(),
      fees: double.tryParse(_controllers['fees']!.text.trim())!,
      feeType: _dropdowns['feeType']!,
      religion: _controllers['religion']!.text.trim(),
      caste: _controllers['caste']!.text.trim(),
    );

    debugPrint("Create Student Object: ${draft.toJson()}");
    try {
      await ref.read(studentsProvider.notifier).addStudent(draft);
      if (mounted) context.pop();
    } catch (e) {
      debugPrint("Error creating student: $e");
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add student — please try again'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Center(
                child: ImagePickerField(
                  controller: _photoController,
                  label: 'Profile Photo',
                  size: 100,
                  shape: BoxShape.circle,
                ),
              ),
              StudentFieldsForm(
                controllers: _controllers,
                values: _dropdowns,
                editable: true,
                isCreate: true,
                lockedFields: const {},
                requiredFields: _requiredFields,
                onDropdownChanged: (key, value) =>
                    setState(() => _dropdowns[key] = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Add Student'),
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
