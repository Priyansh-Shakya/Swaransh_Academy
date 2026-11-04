import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'image_cache_file_image_stub.dart'
    if (dart.library.io) 'image_cache_file_image_io.dart'
    as file_image;

class ImageCacheService {
  const ImageCacheService._();

  static Future<void> evictAll(Iterable<String?> cacheKeys) async {
    final keys = cacheKeys
        .whereType<String>()
        .where((key) => key.isNotEmpty)
        .toSet();

    for (final key in keys) {
      if (!kIsWeb) {
        final cachedFile = await DefaultCacheManager().getFileFromCache(key);
        if (cachedFile != null) {
          await file_image.evictCachedFileImage(cachedFile.file);
        }
      }

      await CachedNetworkImage.evictFromCache(key, cacheKey: key);
      await CachedNetworkImageProvider(key, cacheKey: key).evict();
    }
  }
}
