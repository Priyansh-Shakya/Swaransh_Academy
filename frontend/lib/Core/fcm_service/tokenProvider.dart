import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swaransh_academy/Core/fcm_service/service.dart';
import 'package:swaransh_academy/features/auth/data/users_api_service.dart';

final fcmTokenProvider = StateProvider<String?>((ref) {
  return FcmService.token;
});

final fcmInitProvider = Provider<void>((ref) async {
  final token = await FcmService.init();

  if (token != null) {
    await _handleTokenUpdate(ref, token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await _handleTokenUpdate(ref, newToken);
  });
});

// handle new token
Future<void> _handleTokenUpdate(Ref ref, String newToken) async {
  final oldToken = await getFcmToken();

  final isNew = oldToken != newToken;

  // update provider
  ref.read(fcmTokenProvider.notifier).state = newToken;

  if (isNew) {
    // 🔥 call backend API

    // save AFTER successful update
    await setFcmToken(newToken);

    final token = await FirebaseMessaging.instance.getToken();
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      if (user.userId != null) {
        debugPrint("Updating Fcm token");
        ref
            .read(usersApiServiceProvider)
            .updateUser(user.copyWith(fcmToken: token), user.userId!);
      }
    }

    debugPrint("New token sent to backend: $newToken");
  } else {
    debugPrint("Token unchanged, skipping API call");
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
