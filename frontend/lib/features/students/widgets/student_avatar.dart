import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:swaransh_academy/Core/service/image_cache_file_image_stub.dart'
    if (dart.library.io) 'package:swaransh_academy/Core/service/image_cache_file_image_io.dart'
    as file_image;
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_typography.dart';

class StudentAvatar extends ConsumerStatefulWidget {
  const StudentAvatar({super.key, required this.student, this.radius = 28});

  final Student student;
  final double radius;

  @override
  ConsumerState<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends ConsumerState<StudentAvatar> {
  String? _path;
  ImageProvider? _cachedImage;
  Future<String>? _signedUrl;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl(widget.student.imageUrl);
  }

  @override
  void didUpdateWidget(covariant StudentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.imageUrl != oldWidget.student.imageUrl) {
      _loadSignedUrl(widget.student.imageUrl);
    }
  }

  void _loadSignedUrl(String? path) {
    _path = path;
    _cachedImage = null;
    _signedUrl = null;
    if (path == null || path.isEmpty) return;

    if (kIsWeb) {
      _requestSignedUrl(path);
    } else {
      _loadCachedFile(path);
    }
  }

  Future<void> _loadCachedFile(String path) async {
    try {
      final cached = await DefaultCacheManager().getFileFromCache(path);
      if (!mounted || _path != path) return;
      if (cached != null && cached.validTill.isAfter(DateTime.now())) {
        final image = file_image.cachedFileImage(cached.file);
        if (image != null) {
          setState(() => _cachedImage = image);
          return;
        }
        setState(() => _requestSignedUrl(path));
      } else {
        setState(() => _requestSignedUrl(path));
      }
    } catch (error) {
      debugPrint('Student photo cache lookup failed for $path: $error');
      if (mounted && _path == path) {
        setState(() => _requestSignedUrl(path));
      }
    }
  }

  void _requestSignedUrl(String path) {
    _signedUrl = ref
        .read(supabaseStorageServiceProvider)
        .getSignedUrl(bucket: StorageBucket.studentPhotos, path: path);
  }

  String _initials() {
    final parts = widget.student.name.trim().split(' ');
    return parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : widget.student.name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.departmentColor(widget.student.department);
    final path = _path;
    final signedUrl = _signedUrl;

    Widget fallback() => CircleAvatar(
      radius: widget.radius,
      backgroundColor: color.withOpacity(0.18),
      child: Text(
        _initials(),
        style: AppTypography.titleLarge.copyWith(
          color: color,
          fontSize: widget.radius * 0.65,
        ),
      ),
    );

    if (path == null || path.isEmpty) return fallback();
    if (_cachedImage != null) {
      return CircleAvatar(radius: widget.radius, backgroundImage: _cachedImage);
    }

    return FutureBuilder<String>(
      future: signedUrl,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback();
        return CircleAvatar(
          radius: widget.radius,
          backgroundImage: CachedNetworkImageProvider(
            snapshot.data!,
            cacheKey: path,
          ),
        );
      },
    );
  }
}
