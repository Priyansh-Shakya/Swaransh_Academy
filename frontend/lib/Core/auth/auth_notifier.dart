import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:swaransh_academy/Core/fcm_service/tokenProvider.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_notifier.dart';
import 'package:swaransh_academy/features/auth/data/provider.dart';
import 'package:swaransh_academy/features/auth/data/users_api_service.dart';
import 'package:swaransh_academy/features/auth/domain/user.dart' as model;
import 'package:swaransh_academy/features/role_select/presentation/selectedRoleprovider.dart';

import 'auth_user.dart';
import 'io_platform.dart'; // See Step 2 for why we do this
import 'user_role.dart';

final _supabase = supabase.Supabase.instance.client;

/// Set to a UserRole to bypass Supabase entirely during development.
/// Set to null to use real Supabase auth. Remove before production.
const UserRole? kDebugRole = null;

//! ADMIN Only Role Provider
final isAdminRoleProvider = StateProvider<UserRole>((ref) => UserRole.guest);

class AuthNotifier extends AsyncNotifier<AppUser> {
  // In AuthNotifier, add a field:

  @override
  Future<AppUser> build() async {
    if (kDebugRole != null) {
      debugPrint('[Auth] DEBUG override: $kDebugRole');
      return AppUser.debugUser(kDebugRole!);
    }

    // Update state directly from stream events — never call invalidateSelf()
    // inside the listener, that re-runs build() and causes an infinite loop.
    final subscription = _supabase.auth.onAuthStateChange.listen((event) async {
      debugPrint(
        "Handling AUTH ... From subscription function: $handlingAdminVerification",
      );
      if (handlingAdminVerification) {
        //? for admin purpose. ...
        debugPrint(
          '[Auth] Skipping state update — admin verification in progress',
        );
        return;
      }
      if (event.event == supabase.AuthChangeEvent.signedIn)
        return; // handled explicitly
      debugPrint('[Auth] Event: ${event.event}');
      final user = event.session?.user;
      if (user == null) {
        state = const AsyncValue.data(AppUser.guest);
      } else {
        state = AsyncValue.data(await _resolveUser(user));
      }
    });
    ref.onDispose(subscription.cancel);

    // Initial state on cold start
    final session = _supabase.auth.currentSession;
    if (session == null) return AppUser.guest;
    return _resolveUser(session.user);
  }

  // ---- Public operations ----

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('Sign-in failed');
      state = AsyncValue.data(await _resolveUser(response.user!));
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String? displayName,
    String? role,
  ) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      //* CREATE USER ...
      final isAdmin = ref.read(adminVerificationProvider);
      final fcmToken = ref.read(fcmTokenProvider);
      debugPrint(
        "FCM TOKEN FROM USER NOTIFIER:\n${fcmToken == null ? "NULL" : fcmToken.substring(1, 5)}",
      );
      final user = model.User(
        email: email,
        userName: displayName,
        role: isAdmin ? 'admin' : role,
        fcmToken: fcmToken,
      );
      await ref.read(usersApiServiceProvider).createUser(user);
      if (response.user == null) throw Exception('Sign-up failed');
      state = AsyncValue.data(await _resolveUser(response.user!));
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // 1. Check for Mobile safely (kIsWeb must be checked first)
      if (!kIsWeb && (isAndroid || isIOS)) {
        await _nativeGoogleSignIn();
      } else {
        // 2. Web and Desktop flow
        await _supabase.auth.signInWithOAuth(
          supabase.OAuthProvider.google,
          // The redirectTo is required for Desktop/Web to know where to return
          redirectTo: kIsWeb
              ? null
              : 'io.supabase.swaranshacademy://login-callback',
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    ref.invalidate(isAdminRoleProvider);
    ref.invalidate(adminVerificationProvider);
    ref.invalidate(aiAssistantProvider);
    await _supabase.auth.signOut();
    state = const AsyncValue.data(AppUser.guest);
  }

  // ---- Role resolution ----

  Future<AppUser> _resolveUser(supabase.User user) async {
    final isAdmin = ref.read(isAdminRoleProvider);
    if (isAdmin == UserRole.admin) {
      debugPrint("Switching to ADMIN MODE via adminRoleProvider");
      return _makeUser(user, UserRole.admin);
    }

    try {
      final user0 = await ref.read(usersApiServiceProvider).getCurrentUser();
      ref.read(currentUserProvider.notifier).state = user0;

      if (user0 == null) {
        // No profile row exists yet — shouldn't normally happen since the
        // Google flow creates it first, but don't crash if it does.
        debugPrint(
          "No profile row found in _resolveUser — defaulting to guest",
        );
        return _makeUser(user, UserRole.guest);
      }

      final role = await ref.read(usersApiServiceProvider).checkRole(user0);
      debugPrint("Role fetched from DB: ${role.name}");

      return _makeUser(user, role);
    } catch (e) {
      debugPrint('[Auth] users table query failed: $e → guest');
      return _makeUser(user, UserRole.guest);
    }
  }

  AppUser _makeUser(supabase.User user, UserRole role) => AppUser(
    supabaseUser: user,
    role: role,
    displayName:
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['display_name'] as String?,
    avatarUrl: user.userMetadata?['avatar_url'] as String?,
  );

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        "760961413610-l4qntn2n7gcfo7nu8blem899m4mgjsfs.apps.googleusercontent.com";

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(serverClientId: webClientId);

    // authenticate() always shows the account chooser — no silent reuse
    final googleAccount = await signIn.authenticate();

    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes(['email', 'profile']);

    final idToken = googleAccount.authentication.idToken;
    final accessToken = googleAuthorization?.accessToken;

    if (idToken == null) {
      throw Exception('Google sign-in failed — missing ID token');
    }

    debugPrint(
      "============================== Token: $idToken =================================",
    );

    final response = await _supabase.auth.signInWithIdToken(
      provider: supabase.OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    debugPrint(
      "============================== Response Access Token: ${response.session?.accessToken} =================================",
    );
    final user = response.user;

    debugPrint(
      "============================== User: $user =================================",
    );
    if (user != null) {
      final isNewUser = user.createdAt == user.lastSignInAt;
      final model.User? userExistsInTable = await ref
          .read(usersApiServiceProvider)
          .getCurrentUser();
      debugPrint(
        "====+======+=====+=======+========+======+=====+========== USER EXISTS ALREADY? : $userExistsInTable =============================",
      );
      if (isNewUser || userExistsInTable == null) {
        debugPrint(
          "============================================== New user (Sign Up) ==================================================",
        );
        final isAdmin = ref.read(adminVerificationProvider);
        final role = ref.read(selectedRoleProvider);
        final fcmToken = ref.read(fcmTokenProvider);
        debugPrint(
          "====================================== FCM TOKEN FROM USER NOTIFIER:\n${fcmToken == null ? "NULL" : fcmToken.substring(1, 5)}",
        );
        final role0 = isAdmin
            ? 'admin'
            : (role == UserRole.student)
            ? 'student'
            : 'guest';
        final newUser = model.User(
          email: googleAccount.email, // always populated by Google
          userName: googleAccount
              .displayName, // can be null for some accounts — fine if model.User allows String?
          role: role0, // no role selector in this flow, so default it
          fcmToken: fcmToken,
        );
        debugPrint(
          "---------------------------- CERATING USER FROM GOOGLE AUTH: ${newUser.toJson()}",
        );
        await ref.read(usersApiServiceProvider).createUser(newUser);
      } else {
        debugPrint("Old user (Sign In)");
      }

      state = AsyncValue.data(await _resolveUser(user));
    }
  }

  String _friendlyError(Object e) {
    if (e is supabase.AuthException) {
      return switch (e.message.toLowerCase()) {
        String m when m.contains('invalid login') =>
          'Incorrect email or password.',
        String m when m.contains('email not confirmed') =>
          'Please confirm your email before signing in.',
        String m when m.contains('user already registered') =>
          'An account with this email already exists.',
        String m when m.contains('password') =>
          'Password must be at least 6 characters.',
        _ => e.message,
      };
    }
    return e.toString();
  }

  Future<void> refreshRole() async {
    debugPrint("Resolving user from refresh role function ...");
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    state = AsyncValue.data(await _resolveUser(user));
  }

  // In AuthNotifier, add a field:
  bool handlingAdminVerification = false;
  bool handlingSignUp = false;
  bool authFlowInProgress = false;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser>(
  AuthNotifier.new,
);

final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).valueOrNull?.role ?? UserRole.guest;
});

// To (session-based — CORRECT):
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull?.isAuthenticated ?? false;
});
