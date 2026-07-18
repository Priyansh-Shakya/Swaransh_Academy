import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Generic reusable image picker + Supabase uploader.
///
/// Usage example (in StudentCreatePage or AdmissionFormScreen):
/// ```dart
/// ImagePickerField(
///   label: 'Profile Photo',
///   currentUrl: _imageUrl,
///   bucket: StorageBucket.studentPhotos,
///   storagePath: StoragePath.studentPhoto(userId, 'photo.jpg'),
///   onUploaded: (url) => setState(() => _imageUrl = url),
/// )
/// ```
/// Store the returned URL in your local state/DTO, then send to backend.
class ImagePickerField extends ConsumerStatefulWidget {
  const ImagePickerField({
    super.key,
    required this.bucket,
    required this.storagePath,
    required this.onUploaded,
    this.label = 'Photo',
    this.currentUrl,
    this.size = 96,
    this.shape = BoxShape.circle,
  });

  final String bucket;
  final String storagePath;
  final void Function(String url) onUploaded;
  final String label;
  final String? currentUrl;
  final double size;
  final BoxShape shape;

  @override
  ConsumerState<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends ConsumerState<ImagePickerField> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _localPreviewPath;

  Future<void> _pick(ImageSource source) async {
    Navigator.pop(context);

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() {
      _localPreviewPath = picked.path;
      _uploading = true;
    });

    try {
      final url = await ref.read(supabaseStorageServiceProvider).upload(
            bucket: widget.bucket,
            path: widget.storagePath,
            file: File(picked.path),
          );
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _localPreviewPath = null);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(widget.label, style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => _pick(ImageSource.gallery),
            ),
            if (_localPreviewPath != null || widget.currentUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _SheetOption(
                icon: Icons.delete_outline,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _localPreviewPath = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _localPreviewPath != null
        ? FileImage(File(_localPreviewPath!)) as ImageProvider
        : (widget.currentUrl != null
            ? NetworkImage(widget.currentUrl!)
            : null);

    return GestureDetector(
      onTap: _uploading ? null : _showPickerSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: widget.shape,
              color: AppColors.ivoryDeep,
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.4), width: 2),
              image: imageProvider != null && !_uploading
                  ? DecorationImage(
                      image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: _uploading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold, strokeWidth: 2))
                : imageProvider == null
                    ? Icon(Icons.add_a_photo_outlined,
                        color: AppColors.gold, size: widget.size * 0.35)
                    : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _uploading
                ? 'Uploading...'
                : imageProvider != null
                    ? 'Tap to change'
                    : 'Add ${widget.label}',
            style: AppTypography.caption,
          ),
        ],
      ),
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
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
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
            Text(label,
                style: AppTypography.bodyMedium.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}