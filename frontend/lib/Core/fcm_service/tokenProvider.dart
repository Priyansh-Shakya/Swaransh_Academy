import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swaransh_academy/Core/fcm_service/service.dart';
import 'package:swaransh_academy/features/auth/data/users_api_service.dart';
import 'package:swaransh_academy/features/auth/domain/user.dart';

final fcmTokenProvider = StateProvider<String?>((ref) {
  return FcmService.token;
});

//! MATERIAL APP in my_app.dart listens to this provider directly and runs on every app start.

final fcmInitProvider = Provider<void>((ref) {
  // 1. Listen for Auth changes using your domain User model
  ref.listen<User?>(currentUserProvider, (previous, nextUser) async {
    if (nextUser?.userId != null) {
      // Use your static token variable, or fallback to Firebase if null
      final token =
          FcmService.token ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _handleTokenUpdate(ref, token);
      }
    }
  });

  // 2. Initial check on App Startup
  Future.microtask(() async {
    final token = await FcmService.init();
    if (token != null) {
      await _handleTokenUpdate(ref, token);
    }
  });

  // 3. Listen for mid-session FCM token rotations from Firebase
  final subscription = FirebaseMessaging.instance.onTokenRefresh.listen((
    newToken,
  ) async {
    // Update static variable if you maintain it in FcmService
    FcmService.token = newToken;
    await _handleTokenUpdate(ref, newToken);
  });

  ref.onDispose(() => subscription.cancel());
});

// handle new token
Future<void> _handleTokenUpdate(Ref ref, String newToken) async {
  final oldToken = await getFcmToken();

  if (oldToken == newToken) {
    debugPrint(" 🎅🎅🤶🎅🎅🎅🎅🤶FCM token unchanged, skipping API call");
    ref.read(fcmTokenProvider.notifier).state = newToken;
    return;
  }

  final user = ref.read(currentUserProvider);

  if (user?.userId == null) {
    debugPrint("No authenticated user, cannot update FCM token");
    return;
  }

  try {
    debugPrint(" 😀😀😀😀😀😀😀😀 Updating FCM token...");

    await ref
        .read(usersApiServiceProvider)
        .updateUser(user!.copyWith(fcmToken: newToken), user.userId!);

    // Save only after backend succeeds
    await setFcmToken(newToken);

    // Update provider
    ref.read(fcmTokenProvider.notifier).state = newToken;

    debugPrint("😀😀😀😀😀😀😀😀😀😀😀😀😀 FCM token successfully updated");
  } catch (e) {
    debugPrint("😥😥😣😣😥😥 Failed to update FCM token: $e");
  }
}

// ---------------------------- Helpers---------------------------------------

Future<void> setFcmToken(String token) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setString('fcm_token', token);
}

Future<String?> getFcmToken() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString('fcm_token');
}

// compare with new token
Future<bool?> isNewToken(String newToken) async {
  final pref = await SharedPreferences.getInstance();
  final oldToken = pref.getString('fcm_token');
  if (oldToken == newToken) {
    return true;
  } else {
    false;
  }
  return null;
}
