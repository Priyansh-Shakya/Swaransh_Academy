import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:swaransh_academy/features/auth/data/users_api_service.dart';
import 'package:swaransh_academy/features/auth/domain/user.dart' as model;

import 'auth_user.dart';
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
      final user = model.User(email: email, userName: displayName, role: role);
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
      if (_isAndroid()) {
        await _nativeGoogleSignIn();
      } else {
        await _supabase.auth.signInWithOAuth(
          supabase.OAuthProvider.google,
          redirectTo: 'io.supabase.swaranshacademy://login-callback',
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    ref.invalidate(isAdminRoleProvider);
    await _supabase.auth.signOut();
    state = const AsyncValue.data(AppUser.guest);
  }

  // ---- Role resolution ----

  Future<AppUser> _resolveUser(supabase.User user) async {
    //? Send query ro users table to check role.
    final isAdmin = ref.read(isAdminRoleProvider);
    if (isAdmin == UserRole.admin) {
      debugPrint("Switching to ADMIN MODE via adminRoleProvider");
      return _makeUser(user, UserRole.admin);
    }
    debugPrint("User in resolve user: ${user.toJson()}");
    try {
      final role = await ref.read(usersApiServiceProvider).checkRole();

      if (role == null) {
        debugPrint('[Auth] ${user.email} → no users row found → guest');
        return _makeUser(user, UserRole.guest);
      }

      debugPrint("Role fetched from DB: ${role.name}"); // admin

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
    // Web Client ID from Google Cloud Console — same one configured in
    // Supabase Auth → Providers → Google.
    const webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Google sign-in failed — missing tokens');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: supabase.OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
    if (response.user != null) {
      state = AsyncValue.data(await _resolveUser(response.user!));
    }
  }

  bool _isAndroid() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
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
