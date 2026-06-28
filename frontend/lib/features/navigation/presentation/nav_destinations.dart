import 'package:flutter/material.dart';
import '../../../Core/auth/user_role.dart';

/// One destination list, used to build BOTH the bottom nav bar (Android)
/// and the nav rail (Windows) - so they can never drift out of sync.
///
/// `/admission` is intentionally shared between roles: for guest/student
/// it's "apply", for admin it's "review submitted forms". Same route,
/// different screen content decided by role inside the page itself -
/// keeps one nav entry instead of forking the route per role.
class NavDestination {
  const NavDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.roles,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Set<UserRole> roles;
}

const List<NavDestination> kAllDestinations = [
  NavDestination(
    path: '/home',
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    roles: {UserRole.guest, UserRole.student, UserRole.admin},
  ),
  NavDestination(
    path: '/students',
    label: 'Students',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    roles: {UserRole.student, UserRole.admin},
  ),
  NavDestination(
    path: '/admission',
    label: 'Admission',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    roles: {UserRole.guest, UserRole.student, UserRole.admin},
  ),
  NavDestination(
    path: '/profile',
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    roles: {UserRole.student},
  ),
  NavDestination(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    roles: {UserRole.guest, UserRole.student, UserRole.admin},
  ),
];

List<NavDestination> destinationsForRole(UserRole role) =>
    kAllDestinations.where((d) => d.roles.contains(role)).toList();
