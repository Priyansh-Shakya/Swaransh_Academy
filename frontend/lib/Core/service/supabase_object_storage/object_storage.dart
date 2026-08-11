import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';

class SupabaseStorageService {
  final SupabaseClient client;

  SupabaseStorageService(this.client);

  Future<String> upload({
    required String bucket,
    required String path,
    required File file,
  }) async {
    await client.storage.from(bucket).upload(path, file);

    return client.storage.from(bucket).getPublicUrl(path);
  }

  //* used to upload bytes directly as web doesnt support file upload.
  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    await client.storage.from(bucket).uploadBinary(path, bytes);
    return path; // always the raw path — never a URL
  }

  /// Call this fresh, right before displaying an image. Never cache
  /// the result anywhere persistent (DB, DTO, etc.) — it expires.
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 120, //60 * 60,
  }) {
    return client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }

  String getPublicUrl({required String bucket, required String path}) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 300,
  }) async {
    return client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  Future<void> delete({required String bucket, required String path}) async {
    await client.storage.from(bucket).remove([path]);
  }
}

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SupabaseStorageService(client);
});
