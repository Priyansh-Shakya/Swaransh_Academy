import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../data/admission_notifier.dart';

class AdmissionSuccessScreen extends ConsumerStatefulWidget {
  const AdmissionSuccessScreen({super.key});

  @override
  ConsumerState<AdmissionSuccessScreen> createState() =>
      _AdmissionSuccessScreenState();
}

class _AdmissionSuccessScreenState
    extends ConsumerState<AdmissionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.active.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 44, color: AppColors.active),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Application Submitted!',
                      style: AppTypography.headlineLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your admission form has been submitted successfully. '
                    'The academy will review it and get back to you.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: StaffLineDivider(width: 56)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'What happens next?',
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Step(icon: Icons.hourglass_top_rounded,
                      text: 'Admin reviews your application'),
                  _Step(icon: Icons.check_circle_outline,
                      text: 'You get notified on approval'),
                  _Step(icon: Icons.school_outlined,
                      text: 'Complete payment to activate your enrollment'),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(admissionFormProvider.notifier).reset();
                        context.go('/home');
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}
