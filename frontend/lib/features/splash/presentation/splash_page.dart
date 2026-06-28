import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/staff_line_divider.dart';

/// Shown once per cold app start - not gated on auth/session resolution,
/// just a fixed-duration brand moment before routing to /home.
///
/// Timing (standard Flutter splash conventions, nothing exotic):
///  0ms    - logo starts fading + scaling in
///  600ms  - logo settled, staff-line motif starts drawing in
///  900ms  - staff line settled
///  ~1600ms onward - brief hold
///  2200ms - navigate to /home (StatefulShellRoute root)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _staffOpacity;

  static const _totalDuration = Duration(milliseconds: 900);
  static const _holdAfter = Duration(milliseconds: 1300);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);

    // Logo: fade + gentle scale-up, settles by 600ms (no overshoot/bounce).
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Staff-line motif: draws in just after the logo settles.
    _staffOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(_totalDuration + _holdAfter, () {
      if (mounted) context.go('/home');
    });
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      'app_logo.png',
                      width: 160,
                      height: 160,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note,
                        size: 120,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _staffOpacity.value,
                  child: const StaffLineDivider(width: 72),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
