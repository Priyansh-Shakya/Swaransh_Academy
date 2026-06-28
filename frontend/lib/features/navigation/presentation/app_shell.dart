import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import 'nav_destinations.dart';

/// Breakpoint below which we use a bottom nav bar (phone-shaped windows,
/// Android), and at/above which we use a side rail (Windows desktop).
/// This is a width check, not a platform check on purpose - a resized
/// desktop window or a tablet should get whichever layout actually fits.
const double kRailBreakpoint = 700;

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

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
    // So we must map "tapped position in the visible list" back to its
    // real branch index - never pass the visible-list position straight
    // into goBranch, or a guest's tab taps will open the wrong screen.
    final branchIndices = destinations.map((d) => kAllDestinations.indexOf(d)).toList();
    final selectedVisibleIndex = branchIndices.indexOf(navigationShell.currentIndex);

    void onSelect(int visibleIndex) {
      final branchIndex = branchIndices[visibleIndex];
      navigationShell.goBranch(
        branchIndex,
        // Tapping the already-active tab pops back to that tab's root,
        // matching how Flipkart/most shopping apps behave.
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedVisibleIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: _RailBrandMark(),
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.divider),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedVisibleIndex,
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

class _RailBrandMark extends StatelessWidget {
  const _RailBrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/app_logo.png',
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.music_note,
            color: AppColors.gold,
            size: 32,
          ),
        ),
      ],
    );
  }
}
