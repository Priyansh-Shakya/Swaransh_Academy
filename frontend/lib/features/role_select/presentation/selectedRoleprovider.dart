import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/auth/user_role.dart';


/// Holds the role the user *intends* to sign in as, chosen on RoleSelectPage.
/// Consumed by AuthScreen to decide whether to show the admin code prompt.
/// Cleared after auth completes.
final selectedRoleProvider = StateProvider<UserRole?>((ref) => UserRole.guest);