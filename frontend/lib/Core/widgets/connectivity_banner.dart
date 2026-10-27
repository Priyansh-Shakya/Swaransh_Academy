import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/internet_connection_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(internetConnectionStatusProvider);
    final banner = connectionStatus.when(
      data: (hasInternet) => hasInternet
          ? null
          : _ConnectionBanner(
              message: 'No internet connection',
              onRetry: () => ref.invalidate(internetConnectionStatusProvider),
            ),
      loading: () => null,
      error: (_, _) => _ConnectionBanner(
        message: 'Could not check internet connection',
        onRetry: () => ref.invalidate(internetConnectionStatusProvider),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: child),
        if (banner != null)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: banner,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyDark,
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.goldLight, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Semantics(
              label: 'Retry connection check',
              button: true,
              child: IconButton(
                onPressed: onRetry,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                icon: const Icon(Icons.refresh),
                color: AppColors.goldLight,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
