import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider? cachedFileImage(Object file) {
  if (file is! File) return null;
  return FileImage(file);
}

Future<void> evictCachedFileImage(Object file) async {
  final image = cachedFileImage(file);
  if (image != null) await image.evict();
}
