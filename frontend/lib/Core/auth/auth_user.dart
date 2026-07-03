import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

/// Combines the Supabase identity (User) with the app-level role resolved
/// by the backend (POST /user). Kept separate from Supabase's own User type
/// so the rest of the app never imports supabase_flutter directly - only
/// this file and auth_notifier.dart need to.
class Auth_User {
  const Auth_User({
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

  static const Auth_User guest = _GuestAuth_User();
}

/// Sentinel for unauthenticated state - avoids nullable AuthUser? everywhere.
class _GuestAuth_User extends Auth_User {
  const _GuestAuth_User()
    : super(supabaseUser: const _FakeUser(), role: UserRole.guest);

  @override
  String get id => '';
  @override
  String get email => '';
}

/// Minimal fake to satisfy the non-nullable field when role is guest.
class _FakeUser implements User {
  const _FakeUser();

  @override
  String get id => '';
  @override
  String? get email => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
