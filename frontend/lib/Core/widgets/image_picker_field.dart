import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Holds picked-but-not-yet-uploaded image state for a single image field.
///
/// Works on every platform (web, iOS, Android, desktop) because it never
/// touches `dart:io.File` — only raw bytes via `XFile.readAsBytes()`.
/// `dart:io.File` is a stub on Flutter Web and throws
/// `UnsupportedError: Unsupported operation: _Namespace` the moment you try
/// to actually read it, which is why the old File-based version broke.
///
/// Nothing is sent to Supabase when the user picks or removes an image —
/// that only happens when you call [upload], which you should do from your
/// form's submit handler, right before building the DTO.
///
/// Usage:
/// ```dart
/// final _photoController = ImagePickerController(initialUrl: student.photoUrl);
///
/// // in build():
/// ImagePickerField(controller: _photoController, label: 'Profile Photo')
///
/// // in submit handler:
/// final url = await _photoController.upload(
///   ref: ref,
///   bucket: StorageBucket.studentPhotos,
///   pathBuilder: () => StoragePath.studentPhoto(userId, 'photo.jpg'),
/// );
/// final dto = StudentDto(..., photoUrl: url);
/// await api.createStudent(dto);
/// ```
class ImagePickerController extends ChangeNotifier {
  ImagePickerController({String? initialUrl}) : existingUrl = initialUrl;

  /// Raw bytes of the picked image, not yet uploaded.
  Uint8List? pickedBytes;

  /// Original filename, used to preserve the extension when uploading.
  String? pickedFileName;

  /// URL already on the server (edit mode), or the URL of the last
  /// successful upload once [upload] has run.
  String? existingUrl;

  bool uploading = false;
  String? error;

  bool _removed = false;
  bool get hasLocalChange => pickedBytes != null;

  /// What the widget should render as a preview right now.
  ImageProvider? get previewImage {
    if (pickedBytes != null) return MemoryImage(pickedBytes!);
    if (!_removed && existingUrl != null) return NetworkImage(existingUrl!);
    return null;
  }

  void setBytes(Uint8List bytes, String fileName) {
    pickedBytes = bytes;
    pickedFileName = fileName;
    _removed = false;
    error = null;
    notifyListeners();
  }

  /// Clears the local pick. If there was an existing server URL, it's
  /// hidden from the preview and [upload] will return null for this field
  /// (i.e. "remove the photo") instead of re-uploading anything.
  void remove() {
    pickedBytes = null;
    pickedFileName = null;
    _removed = true;
    error = null;
    notifyListeners();
  }

  /// Call this once, at submit time — not on pick.
  ///
  /// - No pick, no removal -> returns [existingUrl] unchanged (nothing to do).
  /// - Removed, nothing new picked -> returns null.
  /// - New file picked -> uploads it, updates [existingUrl], returns the new URL.
  ///
  /// Throws on upload failure so the caller can decide what to do. [pickedBytes]
  /// is intentionally left intact on failure so the user doesn't lose their
  /// selection and can just retry.
  Future<String?> upload({
    required WidgetRef ref,
    required String bucket,
    required String Function() pathBuilder,
  }) async {
    if (pickedBytes == null) {
      return _removed
          ? null
          : existingUrl; // existingUrl is really "existing path" now
    }
    uploading = true;
    error = null;
    notifyListeners();
    try {
      final path = await ref
          .read(supabaseStorageServiceProvider)
          .uploadBytes(
            bucket: bucket,
            path: pathBuilder(),
            bytes: pickedBytes!,
          );
      existingUrl = path;
      pickedBytes = null;
      pickedFileName = null;
      return path;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      uploading = false;
      notifyListeners();
    }
  }
}

/// Pure pick-and-preview widget. Does NOT touch Supabase — see
/// [ImagePickerController.upload] for that, called at submit time.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.controller,
    this.label = 'Photo',
    this.size = 96,
    this.shape = BoxShape.circle,
    this.resolveDisplayUrl,
  });

  final ImagePickerController controller;
  final String label;
  final double size;
  final BoxShape shape;

  /// Turns a stored path into something actually renderable — a public
  /// URL, a signed URL, whatever fits the bucket. If null, existing
  /// server-side photos won't render (only freshly picked ones will).
  final Future<String> Function(String path)? resolveDisplayUrl;

  Future<void> _pick(BuildContext sheetContext, ImageSource source) async {
    Navigator.pop(sheetContext);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    controller.setBytes(bytes, picked.name);
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(label, style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () => _pick(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => _pick(sheetContext, ImageSource.gallery),
            ),
            if (controller.pickedBytes != null ||
                (!controller._removed &&
                    controller.existingUrl != null &&
                    controller.existingUrl!.isNotEmpty)) ...[
              const SizedBox(height: AppSpacing.sm),
              _SheetOption(
                icon: Icons.delete_outline,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.remove();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds just the image content (no container/border) — null means
  /// "show the add-photo icon instead."
  Widget? _imageContent() {
    if (controller.pickedBytes != null) {
      return Image.memory(controller.pickedBytes!, fit: BoxFit.cover);
    }
    if (!controller._removed &&
        controller.existingUrl != null &&
        controller.existingUrl!.isNotEmpty) {
      if (resolveDisplayUrl == null) return null;
      return FutureBuilder<String>(
        future: resolveDisplayUrl!(controller.existingUrl!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            );
          }
          return Image.network(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final uploading = controller.uploading;
        final content = uploading ? null : _imageContent();

        return GestureDetector(
          onTap: uploading ? null : () => _showPickerSheet(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: shape,
                  color: AppColors.ivoryDeep,
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip
                    .antiAlias, // needed since image is now a child, not DecorationImage
                child: uploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2,
                        ),
                      )
                    : content ??
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.gold,
                            size: size * 0.35,
                          ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                uploading
                    ? 'Uploading...'
                    : content != null
                    ? 'Tap to change'
                    : 'Add $label',
                style: AppTypography.caption,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.navy,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StorageBucket {
  StorageBucket._();
  static const String studentPhotos = 'student-photos';
  static const String admissionPhotos = 'admission-photos';
  static const String coursePhotos = 'course-images';
  static const String adminPhotos = 'admin-photos';
}

class StoragePath {
  StoragePath._();

  static String studentPhoto(String userId, String filename) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = 'students/$userId/${ts}_photo${_ext(filename)}';
    debugPrint("StudentPhoto Url Generator called : $url");
    return url;
  }

  static String admissionPhoto(String draftId, String filename) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = 'pending/admissions/$draftId/${ts}_photo${_ext(filename)}';
    debugPrint("AdmissionPhoto Url Generator called :$url");
    return url;
  }

  static String coursePhoto(String courseName, String userId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = 'courses/$userId/${ts}_photo${_ext(courseName)}';
    debugPrint("CoursePhoto Url Generator called :$url");
    return url;
  }

  static String adminPhoto(String adminName, String userId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final url = 'admin/$userId/${ts}_photo${_ext(adminName)}';
    debugPrint("Admin Photo Url Generator called :$url");
    return url;
  }

  static String _ext(String filename) {
    final i = filename.lastIndexOf('.');
    return i != -1 ? filename.substring(i) : '.jpg';
  }
}
