import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/theme/app_colors.dart';
import 'package:swaransh_academy/Core/theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// 1. BUNTING / GARLAND PAINTER (Draped with center gap for the avatar)
// ---------------------------------------------------------------------------
class BuntingGarlandPainter extends CustomPainter {
  const BuntingGarlandPainter();

  static const List<Color> flagColors = [
    Color(0xFFFF5252), // Coral Red
    AppColors.gold, // Warm Gold
    Color(0xFF40C4FF), // Cyan Blue
    Color(0xFFFFD740), // Bright Amber
    Color(0xFF69F0AE), // Mint Green
    Color(0xFFFF4081), // Pink
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stringPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final avatarZoneRadius = 75.0; // Clear zone around center avatar
    final centerX = size.width / 2;

    // Draw Left Cat-enary String
    final leftPath = Path()
      ..moveTo(0, 14)
      ..quadraticBezierTo(
        (centerX - avatarZoneRadius) * 0.5,
        38,
        centerX - avatarZoneRadius,
        18,
      );
    canvas.drawPath(leftPath, stringPaint);

    // Draw Right Cat-enary String
    final rightPath = Path()
      ..moveTo(centerX + avatarZoneRadius, 18)
      ..quadraticBezierTo(
        centerX +
            avatarZoneRadius +
            (size.width - (centerX + avatarZoneRadius)) * 0.5,
        38,
        size.width,
        14,
      );
    canvas.drawPath(rightPath, stringPaint);

    // Draw Pennant Flags on Left Wing
    _drawPennantsOnArc(
      canvas: canvas,
      startX: 6,
      endX: centerX - avatarZoneRadius - 4,
      midYDrop: 36,
      count: 4,
      colorOffset: 0,
    );

    // Draw Pennant Flags on Right Wing
    _drawPennantsOnArc(
      canvas: canvas,
      startX: centerX + avatarZoneRadius + 4,
      endX: size.width - 6,
      midYDrop: 36,
      count: 4,
      colorOffset: 2,
    );
  }

  void _drawPennantsOnArc({
    required Canvas canvas,
    required double startX,
    required double endX,
    required double midYDrop,
    required int count,
    required int colorOffset,
  }) {
    final step = (endX - startX) / count;
    for (int i = 0; i < count; i++) {
      final x1 = startX + i * step;
      final x2 = x1 + step - 2.5;
      final midX = (x1 + x2) / 2;

      // Approximate the string curve sag
      final t = ((midX - startX) / (endX - startX) - 0.5).abs();
      final topY = 16 + (1 - t * 2) * (midYDrop - 18);

      final flagPaint = Paint()
        ..color = flagColors[(i + colorOffset) % flagColors.length]
        ..style = PaintingStyle.fill;

      // Triangular scalloped pennant hanging down
      final flagPath = Path()
        ..moveTo(x1, topY)
        ..lineTo(x2, topY + 1)
        ..lineTo(midX, topY + 16)
        ..close();

      canvas.drawPath(flagPath, flagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileCardGlowWrapper extends StatefulWidget {
  const ProfileCardGlowWrapper({
    super.key,
    required this.child,
    this.borderRadius,
  });

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<ProfileCardGlowWrapper> createState() => _ProfileCardGlowWrapperState();
}

class _ProfileCardGlowWrapperState extends State<ProfileCardGlowWrapper>
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
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: radius,
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
          padding: const EdgeInsets.all(2.5), // Borders on all 4 sides
          child: child,
        );
      },
      child: ClipRRect(borderRadius: radius, child: widget.child),
    );
  }
}
