import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Roles per the API contract. `guest` is this app's name for an
/// unauthenticated visitor (the contract calls this "Student/Anon").
enum UserRole { guest, student, admin }

/// TEMPORARY STUB. Once the auth feature (Supabase + Google Sign-In) is
/// built, this should be replaced by a provider that derives role from the
/// real session/JWT, not a manually-flipped value. Every other feature
/// should depend on `currentRoleProvider`, not on this notifier directly,
/// so swapping the implementation later doesn't ripple through the app.
class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.student;

  void setRole(UserRole role) => state = role;
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);

/// Stable name every feature should depend on instead of `roleProvider`
/// directly - keeps the swap to real auth a one-file change.
final currentRoleProvider = Provider<UserRole>(
  (ref) => ref.watch(roleProvider),
);
