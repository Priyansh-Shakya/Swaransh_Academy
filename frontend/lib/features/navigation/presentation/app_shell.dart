import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/Core/auth/user_role.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import 'nav_destinations.dart';

/// Breakpoint below which we use a bottom nav bar (phone-shaped windows,
/// Android), and at/above which we use a professional desktop sidebar.
const double kRailBreakpoint = 700;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final destinations = destinationsForRole(role);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= kRailBreakpoint;

    // IMPORTANT: `destinations` is a role-filtered subset of kAllDestinations,
    // but StatefulNavigationShell branch indices are fixed by the FULL list
    // (branch order in app_router.dart mirrors kAllDestinations exactly).
    final branchIndices = destinations
        .map((d) => kAllDestinations.indexOf(d))
        .toList();

    final selectedVisibleIndex = branchIndices.indexOf(
      navigationShell.currentIndex,
    );
    final safeIndex = selectedVisibleIndex < 0 ? 0 : selectedVisibleIndex;

    void onSelect(int visibleIndex) {
      final branchIndex = branchIndices[visibleIndex];
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }

    if (useRail) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: Row(
          children: [
            _DesktopSidebar(
              destinations: destinations,
              selectedIndex: safeIndex,
              onSelected: onSelect,
              role: role,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onSelect,
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.role,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 405, // 1.5x thicker than original 270
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Brand (Logo & title doubled in size)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset(
                    'assets/app_logo.png',
                    width: 200, // 2x original 110 (scaled for 405 container)
                    height: 200,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note,
                      color: AppColors.gold,
                      size: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Swaransh Academy',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 24, // enlarged
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'of Music and Arts',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 15, // enlarged
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),

          // Section Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'NAVIGATION',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),

          // Destinations List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final d = destinations[index];
                final isSelected = index == selectedIndex;

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.navy.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.navy.withOpacity(0.15),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? d.selectedIcon : d.icon,
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            d.label,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.navy
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer Role Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.ivoryDeep,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Role: ${role.name.toUpperCase()}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
