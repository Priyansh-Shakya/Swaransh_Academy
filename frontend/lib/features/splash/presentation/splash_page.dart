/// Shown once per cold app start - not gated on auth/session resolution,
/// just a fixed-duration brand moment before routing to /home.
///
/// Timing (standard Flutter splash conventions, nothing exotic):
///  0ms    - logo starts fading + scaling in
///  600ms  - logo settled, staff-line motif starts drawing in
///  900ms  - staff line settled
///  ~1600ms onward - brief hold
///  2200ms - navigate to /home (StatefulShellRoute root)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/staff_line_divider.dart';

// Replace / verify these imports match your project structure:
// import 'package:your_app/core/constants/app_colors.dart';
// import 'package:your_app/features/auth/providers/auth_providers.dart';
// import 'package:your_app/features/common/widgets/staff_line_divider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  // Intro choreography
  late final Animation<double> _backgroundFade;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTranslationY;

  // Cinematic aura / glow
  late final Animation<double> _haloEntrance;
  late final Animation<double> _haloSettle;

  // Music Staff reveal
  late final Animation<double> _staffExpand;
  late final Animation<double> _staffOpacity;

  // Durations
  static const _introDuration = Duration(milliseconds: 2200);
  static const _minHoldDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: _introDuration,
    );

    // Continuous subtle breathing loop (keeps screen alive if auth/network delays)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // ------------------------------------------------------------
    // 1. BACKGROUND WARMTH
    // ------------------------------------------------------------
    _backgroundFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    // ------------------------------------------------------------
    // 2. LOGO CINEMATIC ENTRANCE & SLOW PUSH-IN
    // ------------------------------------------------------------
    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.08, 0.45, curve: Curves.easeInCubic),
    );

    // Initial scale burst into an ultra-slow theatrical push-in
    _logoScale = TweenSequence<double>([
      // Stage 1: Swift emergence from depth
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.72,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      // Stage 2: Settle onto base focal plane
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      // Stage 3: Slow Netflix-style cinematic drift forward
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 40,
      ),
    ]).animate(_mainController);

    // Floating upward into position
    _logoTranslationY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 30.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -4.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_mainController);

    // ------------------------------------------------------------
    // 3. GLOW & RADIAL AURA
    // ------------------------------------------------------------
    _haloEntrance = Tween<double>(begin: 0.3, end: 1.25).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOutQuart),
      ),
    );

    _haloSettle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.40, curve: Curves.easeOut),
      ),
    );

    // ------------------------------------------------------------
    // 4. MUSICAL STAFF UNFURL (Drawn out horizontally like notation)
    // ------------------------------------------------------------
    _staffExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutExpo),
      ),
    );

    _staffOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.48, 0.72, curve: Curves.easeIn),
    );

    // Start animations
    _mainController.forward();
    _pulseController.repeat(reverse: true);

    // Coordinate minimum display time with authentication
    _coordinateRouting();
  }

  Future<void> _coordinateRouting() async {
    // 1. Kick off visual hold timer
    final minTimer = Future.delayed(_introDuration + _minHoldDuration);

    // 2. Await the underlying authProvider to finish loading from storage/network
    final authCheck = () async {
      try {
        // .future waits until AsyncLoading resolves to AsyncData or AsyncError
        final authState = await ref.read(authProvider.future);
        return authState.isAuthenticated;
      } catch (_) {
        return false;
      }
    }();

    // 3. Wait for BOTH to complete in parallel
    final results = await Future.wait([minTimer, authCheck]);
    final bool isSignedIn = results[1] as bool;

    if (!mounted) return;

    // 4. Navigate directly — no flicker, no hop to /role-select
    if (isSignedIn) {
      context.go('/home');
    } else {
      context.go('/role-select');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController]),
        builder: (context, _) {
          // Subtle harmonic breathing added to the halo
          final double pulseValue = math.sin(_pulseController.value * math.pi);
          final double ambientGlowRadius = 75.0 + (pulseValue * 15.0);
          final double ambientGlowOpacity = 0.18 + (pulseValue * 0.08);

          return FadeTransition(
            opacity: _backgroundFade,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------------------------------------------------
                  // LOGO + RADIAL AURA
                  // ------------------------------------------------
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial depth bloom behind the logo
                      Transform.scale(
                        scale: _haloEntrance.value,
                        child: Opacity(
                          opacity: (_haloSettle.value * ambientGlowOpacity)
                              .clamp(0.0, 1.0),
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: 0.35),
                                  blurRadius: ambientGlowRadius,
                                  spreadRadius: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Academy Logo with translation, scaling, and opacity
                      Transform.translate(
                        offset: Offset(0, _logoTranslationY.value),
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
                                return const Icon(
                                  Icons.music_note_rounded,
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

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // STAFF LINE (Unfurls symmetrically like sheet music)
                  // ------------------------------------------------
                  Transform.scale(
                    scaleX: _staffExpand.value,
                    child: Opacity(
                      opacity: _staffOpacity.value,
                      child: const StaffLineDivider(width: 86),
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
