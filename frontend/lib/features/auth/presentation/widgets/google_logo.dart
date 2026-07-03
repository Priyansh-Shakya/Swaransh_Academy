import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Draws the Google "G" logo using CustomPainter — no PNG asset required.
/// Drop-in widget, sized by [size].
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final blue = const Color(0xFF4285F4);
    final red = const Color(0xFFEA4335);
    final yellow = const Color(0xFFFBBC05);
    final green = const Color(0xFF34A853);

    // Draw the four arc segments of the Google circle
    _arc(canvas, cx, cy, r, -90, 90, red);   // top-right: red
    _arc(canvas, cx, cy, r, 0, 90, yellow);  // bottom-right: yellow
    _arc(canvas, cx, cy, r, 90, 90, green);  // bottom-left: green
    _arc(canvas, cx, cy, r, 180, 90, blue);  // top-left: blue

    // White centre circle cutout
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.60,
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar (the crossbar of the G)
    final barPaint = Paint()..color = blue;
    final barLeft = cx;
    final barRight = cx + r * 0.98;
    final barTop = cy - r * 0.18;
    final barBottom = cy + r * 0.18;
    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
      barPaint,
    );

    // White cutout to make the bar only fill the right half gap
    canvas.drawRect(
      Rect.fromLTRB(cx, barTop, cx + r * 0.98, barBottom),
      Paint()..color = Colors.white,
    );

    // Redraw just the visible blue bar portion
    canvas.drawRect(
      Rect.fromLTRB(cx, barTop, cx + r * 0.90, barBottom),
      barPaint,
    );
  }

  void _arc(Canvas canvas, double cx, double cy, double r,
      double startDeg, double sweepDeg, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(
      rect,
      startDeg * math.pi / 180,
      sweepDeg * math.pi / 180,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
