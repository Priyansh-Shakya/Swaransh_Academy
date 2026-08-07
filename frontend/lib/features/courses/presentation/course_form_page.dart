import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';

const _departments = [
  'Music',
  'Dance',
  'Acting',
  'Music_Video_Production',
  'Other',
];
const _modes = ['Online', 'Offline', 'Hybrid'];
const _tags = ['Instrumental', 'Vocal'];

/// One form for both create and edit - pass `existing` to pre-fill for
/// editing, leave null for create. Avoids two near-duplicate widgets
/// drifting out of sync over time.
class CourseFormPage extends ConsumerStatefulWidget {
  const CourseFormPage({super.key, this.existing});

  final Course? existing;

  @override
  ConsumerState<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends ConsumerState<CourseFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(
    text: widget.existing?.courseName ?? '',
  );
  late final _durationCtrl = TextEditingController(
    text: widget.existing?.duration ?? '',
  );
  late final _feesCtrl = TextEditingController(
    text: widget.existing?.fees.toStringAsFixed(0) ?? '',
  );
  late final _subjectCtrl = TextEditingController(
    text: widget.existing?.mapsToSubject ?? '',
  );

  late final String _department =
      widget.existing?.mapsToDepartment ?? _departments.first;
  late final String _mode = widget.existing?.mode ?? _modes.first;
  late String _tag = widget.existing?.tag ?? _tags.first;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  //* Image field — created once, here, not in build().
  late String? imageUrl = widget.existing?.imageUrl;
  late final ImagePickerController _photoController;

  @override
  void initState() {
    super.initState();

    _photoController = ImagePickerController(
      initialUrl: imageUrl,
    ); // no existing photo on create
  }

  @override
  void dispose() {
    _photoController.dispose();
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    _feesCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Course' : 'Add Course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        imageUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ImagePickerField(
                      controller: _photoController,
                      label: 'Course Photo',
                      size: 100,
                      shape: BoxShape.circle,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display title',
                helperText:
                    'What students see, e.g. "Beginner Guitar Workshop"',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _durationCtrl,
              decoration: const InputDecoration(
                labelText: 'Duration (e.g. "3 months")',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _feesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fees (\u20B9)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              isExpanded: true,

              style: const TextStyle(
                color: AppColors.navy,
              ), // closed-state text
              decoration: InputDecoration(
                labelText: 'Learning mode',
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: _modes
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o.replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.navy),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                (v) => setState(() => _tag = v!);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _tag,
              isExpanded: true,

              style: const TextStyle(
                color: AppColors.navy,
              ), // closed-state text
              decoration: InputDecoration(
                labelText: 'Tag',
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: _tags
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o.replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.navy),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                (v) => setState(() => _tag = v!);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Admission pre-fill mapping',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              'Used to pre-fill the Admission Form when a student taps "Apply Now" - '
              'keep these matching the form\'s actual enum/subject values, not the '
              'display title above.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _department,
              isExpanded: true,

              style: const TextStyle(
                color: AppColors.navy,
              ), // closed-state text
              decoration: InputDecoration(
                labelText: 'Maps to department',
                filled: true,
                fillColor: AppColors.surface,
              ),
              items: _departments
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o.replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.navy),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                (v) => setState(() => _tag = v!);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Maps to subject',
                helperText:
                    'Exact value the admission form expects, e.g. "Guitar"',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = ref.read(supabaseProvider).auth.currentSession?.user.id;

    if (userId != null) {
      try {
        imageUrl = await _photoController.upload(
          ref: ref,
          bucket: StorageBucket.coursePhotos,
          pathBuilder: () =>
              StoragePath.coursePhoto(userId, _nameCtrl.text.trim()),
          isPrivate: false,
        );
        debugPrint("Photo URL available: $imageUrl");
      } catch (e) {
        debugPrint("Error on image upload, Course Create: $e");
        // photo upload failed — proceeding without a photo rather than
        // blocking the whole student creation. Reconsider if a photo
        // should be mandatory for your flow.
      }
    }

    context.pop(); //* POP screen

    final draft = Course(
      id:
          widget.existing?.id ??
          0, // ignored by addCourse, used by updateCourse
      courseName: _nameCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      fees: double.parse(_feesCtrl.text.trim()),
      mode: _mode,
      tag: _tag,
      mapsToDepartment: _department,
      mapsToSubject: _subjectCtrl.text.trim(),
      imageUrl: imageUrl,
    );

    if (_isEdit) {
      await ref.read(coursesProvider.notifier).updateCourse(draft);
    } else {
      await ref.read(coursesProvider.notifier).addCourse(draft);
    }
  }
}
