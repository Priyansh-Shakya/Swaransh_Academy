import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/theme/app_spacing.dart';

class PartyHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Cone Body with INWARD (concave) bottom curve
    // The control point (w * 0.5, h * 0.70) pulls the bottom curve upward into the hat
    // 1. Draw Cone Body with true circular arc matching R=30
    final path = Path()
      ..moveTo(w * 0.5, 0) // Peak
      ..lineTo(w * 0.1, h * 0.90) // Bottom-left corner
      ..arcToPoint(
        Offset(w * 0.9, h * 0.90), // Bottom-right corner
        radius: const Radius.circular(
          30,
        ), // Exact match for StudentAvatar(radius: 30)
        clockwise: true, // Curves inward/upward
      )
      ..close();

    final conePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF3366), Color(0xFFFF9933)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, conePaint);

    // 2. Draw Festive Curved Stripes (curving along with the bottom contour)
    final stripePaint = Paint()
      ..color = const Color(0xFFFFEB3B).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Upper stripe (curved inward)
    final stripePath1 = Path()
      ..moveTo(w * 0.36, h * 0.35)
      ..quadraticBezierTo(w * 0.5, h * 0.28, w * 0.64, h * 0.35);
    canvas.drawPath(stripePath1, stripePaint);

    // Lower stripe (curved inward)
    final stripePath2 = Path()
      ..moveTo(w * 0.23, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.52, w * 0.77, h * 0.62);
    canvas.drawPath(stripePath2, stripePaint);

    // 3. Draw Pom-pom on top
    // (Kept your bright green accent or whatever color you used)
    final pomPomPaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(Offset(w * 0.5, 2), 4.5, pomPomPaint);

    // White shine highlight on pom-pom
    final fluffPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.5 - 1.5, 0.5), 1.5, fluffPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BirthdayAvatarWrapper extends StatelessWidget {
  const BirthdayAvatarWrapper({
    super.key,
    required this.child,
    this.isBirthday = false,
  });

  final Widget child;
  final bool isBirthday;

  @override
  Widget build(BuildContext context) {
    if (!isBirthday) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // Party Hat tilted gently over top-left of the avatar
        Positioned(
          top: -41,
          left: -13.5,
          child: Transform.rotate(
            angle: -math.pi / 10, // -15 degrees tilt
            child: SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(painter: PartyHatPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

class BirthdayGlowContainer extends StatefulWidget {
  const BirthdayGlowContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
  });

  final Widget child;
  final double borderRadius;

  @override
  State<BirthdayGlowContainer> createState() => _BirthdayGlowContainerState();
}

class _BirthdayGlowContainerState extends State<BirthdayGlowContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            gradient: SweepGradient(
              transform: GradientRotation(_controller.value * 2 * math.pi),
              colors: const [
                Color(0xFFFF5252),
                Color(0xFFFFD700),
                Color(0xFF40C4FF),
                Color(0xFFFF4081),
                Color(0xFFFF5252),
              ],
            ),
          ),
          padding: const EdgeInsets.all(2.0), // Border thickness
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

//* Sparkel Bomb effect
class ConfettiPopperBlast extends StatefulWidget {
  const ConfettiPopperBlast({
    super.key,
    this.particleCount = 55,
    this.duration = const Duration(milliseconds: 2800),
  });

  final int particleCount;
  final Duration duration;

  @override
  State<ConfettiPopperBlast> createState() => _ConfettiPopperBlastState();
}

class _ConfettiPopperBlastState extends State<ConfettiPopperBlast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();

    const colors = [
      Color(0xFFFFD700), // Shiny Gold Foil
      Color(0xFFFF1744), // Crimson
      Color(0xFF00E676), // Emerald
      Color(0xFF2979FF), // Electric Blue
      Color(0xFFFF4081), // Hot Pink
      Color(0xFFFFAB00), // Amber
      Color(0xFFE040FB), // Magenta
    ];

    _particles = List.generate(widget.particleCount, (i) {
      final angle =
          -math.pi / 2 + (_rnd.nextDouble() - 0.5) * 1.6; // Spray upwards
      final speed = _rnd.nextDouble() * 380 + 220;
      return _ConfettiParticle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: colors[_rnd.nextInt(colors.length)],
        width: _rnd.nextDouble() * 7 + 4,
        height: _rnd.nextDouble() * 11 + 6,
        rotSpeed: (_rnd.nextDouble() - 0.5) * 12,
        isRibbon: _rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;
          return CustomPaint(
            painter: _ConfettiPainter(particles: _particles, progress: t),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.width,
    required this.height,
    required this.rotSpeed,
    required this.isRibbon,
  });

  final double vx;
  final double vy;
  final Color color;
  final double width;
  final double height;
  final double rotSpeed;
  final bool isRibbon;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    // Origin starts from near the bottom center
    final originX = size.width / 2;
    final originY = size.height * 0.85;
    const gravity = 550.0; // Gravity pulling strips down
    final t = progress * 2.5;

    for (final p in particles) {
      final x = originX + p.vx * t;
      final y = originY + p.vy * t + 0.5 * gravity * t * t;

      // Fade out smoothly towards end
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotSpeed * t);

      if (p.isRibbon) {
        // Render 3D tumbling paper foil ribbon
        final scaleX = math.cos(p.rotSpeed * 2 * t);
        canvas.scale(scaleX, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.width,
              height: p.height,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        // Foil circular glitter dot
        canvas.drawCircle(Offset.zero, p.width * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class SheetGlowWrapper extends StatefulWidget {
  const SheetGlowWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<SheetGlowWrapper> createState() => _SheetGlowWrapperState();
}

class _SheetGlowWrapperState extends State<SheetGlowWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg + 2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withOpacity(0.3),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
            gradient: SweepGradient(
              transform: GradientRotation(_controller.value * 2 * math.pi),
              colors: const [
                Color(0xFFFF5252),
                Color(0xFFFFD700),
                Color(0xFF40C4FF),
                Color(0xFFFF4081),
                Color(0xFFFF5252),
              ],
            ),
          ),
          padding: const EdgeInsets.only(top: 2.5, left: 2.5, right: 2.5),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
