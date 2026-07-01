import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared across Student Detail (admin), Student's own Profile, and (later)
/// the Admission Form - all three render largely the same field set, just
/// with different read/write permissions layered on top. One widget here
/// means field order/labels/grouping never drift apart between those three
/// screens as the app grows.
///
/// `editable` toggles the WHOLE widget between read-only display and
/// editable form fields - no per-field toggling, matches the page-level
/// edit/done pattern used elsewhere in the app.
///
/// `lockedFields` lets a caller mark specific field keys as always
/// read-only even while editable=true - e.g. a student editing their own
/// profile must never be able to change fees/status/scholar_no/email, but
/// admin editing the same student can.
class StudentFieldsForm extends StatelessWidget {
  const StudentFieldsForm({
    super.key,
    required this.controllers,
    required this.values,
    required this.editable,
    this.lockedFields = const {},
    this.visibleSections = const {
      StudentFieldSection.identity,
      StudentFieldSection.contact,
      StudentFieldSection.course,
      StudentFieldSection.admin,
    },
    this.onDropdownChanged,
  });

  /// One TextEditingController per free-text field key
  /// (name, fatherName, dob, contact, email, address, scholarNo, fees...).
  final Map<String, TextEditingController> controllers;

  /// Current value for every dropdown/enum field key
  /// (gender, educationQualification, department, admissionType,
  /// learningMode, batch, feeType, status).
  final Map<String, String?> values;

  final bool editable;
  final Set<String> lockedFields;
  final Set<StudentFieldSection> visibleSections;
  final void Function(String fieldKey, String newValue)? onDropdownChanged;

  bool _isLocked(String key) => !editable || lockedFields.contains(key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visibleSections.contains(StudentFieldSection.identity)) ...[
          const _SectionHeader('Personal Details'),
          _text(context, 'name', 'Full Name'),
          _text(context, 'fatherName', "Father's Name"),
          _text(context, 'dob', 'Date of Birth', hint: 'YYYY-MM-DD'),
          _dropdown(context, 'gender', 'Gender', kGenderOptions),
          _dropdown(
            context,
            'educationQualification',
            'Education Qualification',
            kEducationOptions,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visibleSections.contains(StudentFieldSection.contact)) ...[
          const _SectionHeader('Contact'),
          _text(context, 'contact', 'Contact Number', keyboardType: TextInputType.phone),
          _text(
            context,
            'email',
            'Email',
            keyboardType: TextInputType.emailAddress,
            helperText: _isLocked('email')
                ? 'Email is used for login and can only be changed by admin.'
                : null,
          ),
          _text(context, 'address', 'Address', maxLines: 2),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visibleSections.contains(StudentFieldSection.course)) ...[
          const _SectionHeader('Course & Enrollment'),
          _dropdown(context, 'department', 'Department', kDepartmentOptions),
          _text(context, 'subject', 'Subject'),
          _dropdown(context, 'admissionType', 'Admission Type', kAdmissionTypeOptions),
          _dropdown(context, 'learningMode', 'Learning Mode', kLearningModeOptions),
          _dropdown(context, 'batch', 'Batch', kBatchOptions),
          Row(
            children: [
              Expanded(child: _text(context, 'startTime', 'Start Time', hint: 'HH:MM')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _text(context, 'endTime', 'End Time', hint: 'HH:MM')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visibleSections.contains(StudentFieldSection.admin)) ...[
          const _SectionHeader('Admin / Fees (admin-only edits)'),
          _text(context, 'scholarNo', 'Scholar No.'),
          _text(context, 'dateOfJoining', 'Date of Joining', hint: 'YYYY-MM-DD'),
          _text(
            context,
            'fees',
            'Fees (\u20B9)',
            keyboardType: TextInputType.number,
          ),
          _dropdown(context, 'feeType', 'Fee Type', kFeeTypeOptions),
          _text(context, 'religion', 'Religion (optional)'),
          _text(context, 'caste', 'Caste (optional)'),
        ],
      ],
    );
  }

  Widget _text(
    BuildContext context,
    String key,
    String label, {
    String? hint,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final controller = controllers[key];
    if (controller == null) return const SizedBox.shrink();
    final locked = _isLocked(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: locked
          ? _ReadOnlyField(label: label, value: controller.text)
          : TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                helperText: helperText,
              ),
            ),
    );
  }

  Widget _dropdown(
    BuildContext context,
    String key,
    String label,
    List<String> options,
  ) {
    final value = values[key];
    final locked = _isLocked(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: locked
          ? _ReadOnlyField(label: label, value: value?.replaceAll('_', ' ') ?? '-')
          : DropdownButtonFormField<String>(
              initialValue: value,
              decoration: InputDecoration(labelText: label),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onDropdownChanged?.call(key, v);
              },
            ),
    );
  }
}

enum StudentFieldSection { identity, contact, course, admin }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTypography.titleLarge.copyWith(color: AppColors.gold)),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

// ---- Shared enum option lists (mirror OpenAPI contract enums) ----
const kGenderOptions = ['male', 'female', 'nonbinary'];
const kEducationOptions = ['Primary_School', 'High_School', 'Bachelors', 'Masters'];
const kDepartmentOptions = ['Music', 'Dance', 'Acting', 'Music_Video_Production', 'Other'];
const kAdmissionTypeOptions = ['Regular', 'Band_Training', 'Summer_Camp', 'Custom'];
const kLearningModeOptions = ['Online', 'Offline', 'Hybrid'];
const kBatchOptions = ['Morning', 'Evening'];
const kFeeTypeOptions = ['Monthly', 'Quarterly', 'Half_Yearly', 'Yearly'];
