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

  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOffset;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;
  late final Animation<double> _staffOpacity;
  late final Animation<double> _staffScale;

  static const _animationDuration = Duration(milliseconds: 1500);
  static const _holdAfter = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    // ------------------------------------------------------------
    // BACKGROUND
    // ------------------------------------------------------------
    //
    // Starts slightly transparent/dim and gently settles into
    // the full ivory background.
    //
    _backgroundOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
    );

    // ------------------------------------------------------------
    // LOGO
    // ------------------------------------------------------------

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeInOut),
    );

    // Starts noticeably small and grows into place.
    //
    // The slight overshoot makes the arrival feel physical without
    // becoming a "bouncy" animation.
    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.55,
              end: 1.04,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 75,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.04,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 10,
          ),
          TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 15),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.80),
          ),
        );
    // Logo subtly rises while appearing.
    _logoOffset = Tween<double>(begin: 22.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // ------------------------------------------------------------
    // GLOW / HALO
    // ------------------------------------------------------------
    //
    // A very subtle bloom behind the logo.
    // This makes the logo feel like it is "arriving" rather than
    // simply being painted onto the screen.
    //
    _glowOpacity =
        TweenSequence<double>([
          // Glow appears quickly.
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 0.20,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 35,
          ),

          // Glow fades completely away.
          TweenSequenceItem(
            tween: Tween(
              begin: 0.20,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 65,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.78),
          ),
        );

    _glowScale = Tween<double>(begin: 0.45, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // ------------------------------------------------------------
    // STAFF LINES
    // ------------------------------------------------------------
    //
    // Come in after the logo has mostly settled.
    //
    _staffOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.90, curve: Curves.easeOutCubic),
    );

    _staffScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    Future.delayed(_animationDuration + _holdAfter, () {
      if (mounted) {
        context.go('/role-select');
      }
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: 0.92 + (_backgroundOpacity.value * 0.08),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------------------------------------------------
                  // LOGO + GLOW
                  // ------------------------------------------------
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft halo behind the logo.
                      Transform.scale(
                        scale: _glowScale.value,
                        child: Opacity(
                          opacity: _glowOpacity.value,
                          child: Transform.scale(
                            scale: _glowScale.value,
                            child: Opacity(
                              opacity: _glowOpacity.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 65,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Actual logo.
                      Transform.translate(
                        offset: Offset(0, _logoOffset.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Image.asset(
                              'assets/app_logo.png',
                              width: 240,
                              height: 240,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('SPLASH LOGO ERROR: $error');
                                debugPrintStack(stackTrace: stackTrace);

                                return const Icon(
                                  Icons.music_note,
                                  size: 120,
                                  color: AppColors.navy,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // STAFF LINE
                  // ------------------------------------------------
                  Transform.scale(
                    scaleX: _staffScale.value,
                    child: Opacity(
                      opacity: _staffOpacity.value,
                      child: const StaffLineDivider(width: 72),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
