import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';

/// Rows saved before the path-only migration hold full URLs; new rows hold
/// bare paths. Handle both until old rows are migrated or age out.
String resolvePublicImage(
  WidgetRef ref, {
  required String bucket,
  required String pathOrUrl,
}) {
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return pathOrUrl; // legacy row, already a usable URL
  }
  return ref
      .read(supabaseStorageServiceProvider)
      .getPublicUrl(bucket: bucket, path: pathOrUrl);
}
