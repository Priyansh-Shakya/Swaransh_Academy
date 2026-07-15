import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/widgets/student_fields_form.dart';

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

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final draft = CreateStudent(
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
      appBar: AppBar(
        title: const Text('Add Student'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text('Save', style: TextStyle(color: AppColors.gold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              StudentFieldsForm(
                isCreate: true,
                controllers: _controllers,
                values: _dropdowns,
                editable: true,
                lockedFields: const {},
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
