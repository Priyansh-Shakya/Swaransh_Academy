import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import 'academy_content.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final isSignedIn = role != UserRole.guest;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [

          // ---- Account section ----
          _SectionLabel('Account'),
          if (isSignedIn)
            _AccountTile(role: role)
          else
            _SettingsTile(
              icon: Icons.login,
              iconColor: AppColors.navy,
              title: 'Sign In',
              subtitle: 'Access your student profile or admin panel',
              onTap: () {
                // TODO: launch Supabase Google Sign-In flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auth coming soon')),
                );
              },
            ),

          const _Divider(),

          // ---- Support & Info ----
          _SectionLabel('Support & Info'),
          _SettingsTile(
            icon: Icons.headset_mic_outlined,
            iconColor: AppColors.deptActing,
            title: 'Contact Support',
            subtitle: 'Get in touch with the academy',
            onTap: () => _showContactSheet(context),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: AppColors.gold,
            title: 'About Swaransh Academy',
            subtitle: 'Our story, our team',
            onTap: () => context.push('/settings/about'),
          ),

          const _Divider(),

          // ---- App ----
          _SectionLabel('App'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.deptMusic,
            title: 'Notifications',
            subtitle: 'Fee reminders, announcements',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings — coming soon')),
            ),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'App Version',
            subtitle: 'v1.0.0',
            onTap: null,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ---- Logout (only when signed in) ----
          if (isSignedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ContactSheet(),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to guest mode.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(roleProvider.notifier).setRole(UserRole.guest);
              Navigator.pop(ctx);
              // TODO: also call Supabase signOut() once auth is wired
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ---- Account tile (signed-in state) ----

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.admin => 'Administrator',
      UserRole.student => 'Student',
      _ => 'Guest',
    };
    final color = role == UserRole.admin ? AppColors.deptProduction : AppColors.deptActing;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(Icons.person, color: color),
      ),
      title: Text(
        'Signed in as $label',
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // TODO: replace with real email from Supabase session
        'user@gmail.com',
        style: AppTypography.bodySmall,
      ),
    );
  }
}

// ---- Contact support bottom sheet ----

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Contact Support', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Reach out to us for admission queries, fee issues, or any help.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: AcademyContent.contactEmail,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: AcademyContent.contactPhone,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ---- Generic settings tile ----

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 4),
      child: Text(label, style: AppTypography.label),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(height: 1),
    );
  }
}
