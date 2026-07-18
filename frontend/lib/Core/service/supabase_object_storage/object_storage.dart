import 'dart:io';
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
    await client.storage
        .from(bucket)
        .upload(path, file);

    return client.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 300,
  }) async {
    return client.storage
        .from(bucket)
        .createSignedUrl(path, expiresIn);
  }

  Future<void> delete({
    required String bucket,
    required String path,
  }) async {
    await client.storage
        .from(bucket)
        .remove([path]);
  }
}

final supabaseStorageServiceProvider =
    Provider<SupabaseStorageService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SupabaseStorageService(client);
});