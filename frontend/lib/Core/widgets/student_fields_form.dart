import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';

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
  final bool isCreate;
  const StudentFieldsForm({
    super.key,
    required this.isCreate,
    required this.controllers,
    required this.values,
    required this.editable,
    this.lockedFields = const {},
    this.requiredFields = const {},
    this.visibleSections = const {
      StudentFieldSection.identity,
      StudentFieldSection.contact,
      StudentFieldSection.course,
      StudentFieldSection.admin,
    },
    this.onDropdownChanged,
    // ── Image picker (optional) ──
    this.imagePickerController,
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

  /// Fields in this set get a red asterisk in their label when editable.
  final Set<String> requiredFields;
  final Set<StudentFieldSection> visibleSections;
  final void Function(String fieldKey, String newValue)? onDropdownChanged;

  /// Profile Image  fields
  final ImagePickerController? imagePickerController;

  bool _isLocked(String key) => !editable || lockedFields.contains(key);
  bool _isRequired(String key) => editable && requiredFields.contains(key);

  String _labelWithMarker(String key, String label) =>
      _isRequired(key) ? '$label *' : label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visibleSections.contains(StudentFieldSection.identity)) ...[
          const _SectionHeader('Personal Details'),
          //* Image picker — shown only when config is provided
          //* Image picker — shown only when a controller is provided
          if (imagePickerController != null) ...[
            Center(
              child: ImagePickerField(
                controller: imagePickerController!,
                label: 'Profile Photo',
                size: 100,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          _text(context, 'name', 'Full Name'),
          _text(context, 'fatherName', "Father's Name"),
          _pickerField(context, 'dob', 'Date of Birth', isDate: true),
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
          _text(
            context,
            'contact',
            'Contact Number',
            keyboardType: TextInputType.phone,
          ),
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
          _dropdown(
            context,
            'admissionType',
            'Admission Type',
            kAdmissionTypeOptions,
          ),
          _dropdown(
            context,
            'learningMode',
            'Learning Mode',
            kLearningModeOptions,
          ),
          _dropdown(context, 'batch', 'Batch', kBatchOptions),
          Row(
            children: [
              Expanded(
                child: _pickerField(
                  context,
                  'startTime',
                  'Start Time',
                  isDate: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _pickerField(
                  context,
                  'endTime',
                  'End Time',
                  isDate: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visibleSections.contains(StudentFieldSection.admin)) ...[
          const _SectionHeader('Admin / Fees (admin-only edits)'),
          if (!isCreate)
            _text(
              context,
              'scholarNo',
              'Scholar No.',
              helperText: _isLocked('scholarNo')
                  ? 'Scholar Number is asigned by Database itself and cannot be changed.'
                  : null,
            ), //* Only Show Scholar Number in Read Mode
          _pickerField(
            context,
            'dateOfJoining',
            'Date of Joining',
            isDate: true,
          ),
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
    final displayLabel = _labelWithMarker(key, label);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: locked
          ? _ReadOnlyField(label: label, value: controller.text)
          : TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: displayLabel,
                hintText: hint,
                helperText: helperText,

                labelStyle: _isRequired(key)
                    ? TextStyle(color: AppColors.textSecondary)
                    : null,
              ),
            ),
    );
  }

  //? For Date Time Picking
  Widget _pickerField(
    BuildContext context,
    String key,
    String label, {
    required bool isDate,
  }) {
    final controller = controllers[key];
    if (controller == null) return const SizedBox.shrink();
    final locked = _isLocked(key);

    if (locked) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _ReadOnlyField(label: label, value: controller.text),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return GestureDetector(
            onTap: () async {
              if (isDate) {
                DateTime initial = DateTime.now();
                if (value.text.isNotEmpty) {
                  try {
                    initial = DateTime.parse(value.text);
                  } catch (_) {}
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.text =
                      '${picked.year.toString().padLeft(4, '0')}-'
                      '${picked.month.toString().padLeft(2, '0')}-'
                      '${picked.day.toString().padLeft(2, '0')}';
                }
              } else {
                TimeOfDay initial = TimeOfDay.now();
                if (value.text.isNotEmpty) {
                  try {
                    final parts = value.text.split(':');
                    initial = TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    );
                  } catch (_) {}
                }
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  controller.text =
                      '${picked.hour.toString().padLeft(2, '0')}:'
                      '${picked.minute.toString().padLeft(2, '0')}:00';
                }
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _labelWithMarker(key, label),
                suffixIcon: Icon(
                  isDate
                      ? Icons.calendar_today_outlined
                      : Icons.access_time_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                value.text.isEmpty
                    ? (isDate ? 'Select date' : 'Select time')
                    : value.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: value.text.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown(
    BuildContext context,
    String key,
    String label,
    List<String> options,
  ) {
    final rawValue = values[key];
    final value = (rawValue == null || rawValue.isEmpty) ? null : rawValue;
    final locked = _isLocked(key);
    final displayLabel = _labelWithMarker(key, label);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: locked
          ? _ReadOnlyField(
              label: label,
              value: value?.replaceAll('_', ' ') ?? '-',
            )
          : DropdownButtonFormField<String>(
              initialValue: value,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(labelText: displayLabel),
              iconEnabledColor: AppColors.textPrimary,
              items: options
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
      child: Text(
        title,
        style: AppTypography.titleLarge.copyWith(color: AppColors.gold),
      ),
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
        Text(value.isEmpty ? '-' : value, style: AppTypography.bodyLarge),
      ],
    );
  }
}

// ---- Shared enum option lists (mirror OpenAPI contract enums) ----
const kGenderOptions = ['male', 'female', 'non-binary'];
const kEducationOptions = [
  'Primary_School',
  'High_School',
  'Bachelors',
  'Masters',
];
const kDepartmentOptions = [
  'Music',
  'Dance',
  'Acting',
  'Music_Video_Production',
  'Other',
];
const kAdmissionTypeOptions = [
  'Regular',
  'Band_Training',
  'Summer_Camp',
  'Custom',
];
const kLearningModeOptions = ['Online', 'Offline', 'Hybrid'];
const kBatchOptions = ['Morning', 'Evening'];
const kFeeTypeOptions = ['Monthly', 'Quarterly', 'Half_Yearly', 'Yearly'];
