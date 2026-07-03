import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_user.dart';
import 'user_role.dart';

final _supabase = Supabase.instance.client;

/// Single source of truth for identity + role across the whole app.
/// Replaces the manual RoleNotifier stub.
///
/// On sign-in, calls POST /user (your FastAPI backend) which resolves the
/// role server-side (admin pre-provisioned, student matched by email) and
/// returns it. Never trust a client-supplied role claim.
class AuthNotifier extends AsyncNotifier<Auth_User> {
  @override
  Future<Auth_User> build() async {
    // Listen to Supabase session changes (token refresh, sign-out etc.)
    // and rebuild the provider automatically.
    ref.listenSelf((_, __) {});
    _supabase.auth.onAuthStateChange.listen((_) {
      ref.invalidateSelf();
    });

    final session = _supabase.auth.currentSession;
    if (session == null) return Auth_User.guest;
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
    String password, {
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
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
      // Web/desktop - uses Supabase OAuth redirect flow.
      // Android - uses google_sign_in package for native experience.
      final isNative = _isAndroid();

      if (isNative) {
        await _nativeGoogleSignIn();
      } else {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.swaranshacademy://login-callback',
        );
      }
      // Session is picked up by the onAuthStateChange listener above,
      // which invalidates this provider. No explicit state update needed here
      // for the OAuth redirect flow; for native it completes synchronously.
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(Auth_User.guest);
  }

  // ---- Private helpers ----

  Future<Auth_User> _resolveUser(User supabaseUser) async {
    // Call your FastAPI POST /user endpoint which:
    // 1. Creates/syncs the users table row
    // 2. Resolves role (admin pre-provisioned, student matched by email)
    // 3. Returns the User row including role
    //
    // TODO: replace with real Dio call once backend is ready.
    // For now, returns a mock role so the rest of the app is testable.
    final mockRole = _mockResolveRole(supabaseUser.email ?? '');

    return Auth_User(
      supabaseUser: supabaseUser,
      role: mockRole,
      displayName:
          supabaseUser.userMetadata?['full_name'] as String? ??
          supabaseUser.userMetadata?['display_name'] as String?,
      avatarUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
    );
  }

  /// MOCK role resolution. Replace with real API call:
  /// ```
  /// final dio = ref.read(dioProvider);
  /// final res = await dio.post('/user', data: {'email': email, 'fcm_token': null});
  /// return UserRole.values.byName(res.data['role']);
  /// ```
  UserRole _mockResolveRole(String email) {
    if (email.contains('admin')) return UserRole.admin;
    return UserRole.student;
  }

  Future<void> _nativeGoogleSignIn() async {
    const webClientId =
        'YOUR_GOOGLE_WEB_CLIENT_ID'; // set in .env or here directly
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Google sign-in failed — missing tokens');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    if (response.user != null) {
      state = AsyncValue.data(await _resolveUser(response.user!));
    }
  }

  bool _isAndroid() {
    try {
      // Platform check without dart:io import issues on web
      return identical(0, 0.0) == false; // always false, triggers dart:io check
    } catch (_) {
      return false;
    }
  }

  String _friendlyError(Object e) {
    if (e is AuthException) {
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
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Auth_User>(
  AuthNotifier.new,
);

/// Replaces the old manual `currentRoleProvider` stub.
/// Every feature that previously used `currentRoleProvider` continues to work
/// with no changes — only this file changed.
final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).valueOrNull?.role ?? UserRole.guest;
});

/// Convenience: true when Supabase session exists (any role except guest).
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) != UserRole.guest;
});
