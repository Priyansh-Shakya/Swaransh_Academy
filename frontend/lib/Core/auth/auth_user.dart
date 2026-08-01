import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.supabaseUser,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  final User supabaseUser;
  final UserRole role;
  final String? displayName;
  final String? avatarUrl;

  String get id => supabaseUser.id;
  String get email => supabaseUser.email ?? '';
  bool get isAuthenticated => id.isNotEmpty;

  // Helper for greeting fallbacks
  String get name =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : 'there';

  /// Unauthenticated sentinel — returned when there is no Supabase session.
  static const AppUser guest = _GuestAuthUser();

  /// Debug-only: creates a fake authenticated user with the given role.
  /// Used when kDebugRole is set in auth_notifier.dart.
  factory AppUser.debugUser(UserRole role) => AppUser(
    supabaseUser: const _FakeUser(),
    role: role,
    displayName: role == UserRole.admin ? 'Debug Admin' : 'Debug Student',
  );
}

class _GuestAuthUser extends AppUser {
  const _GuestAuthUser()
    : super(supabaseUser: const _FakeUser(), role: UserRole.guest);

  @override
  String get id => '';
  @override
  String get email => '';
}

class _FakeUser implements User {
  const _FakeUser();

  @override
  String get id => '';
  @override
  String? get email => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
