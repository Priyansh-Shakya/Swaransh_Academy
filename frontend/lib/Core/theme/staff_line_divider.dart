import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Signature motif: five thin horizontal lines at varying opacity, echoing
/// sheet-music staff lines without literally drawing a music note on every
/// screen. Use sparingly as a section break - not on every card.
class StaffLineDivider extends StatelessWidget {
  const StaffLineDivider({
    super.key,
    this.width = 64,
    this.color = AppColors.staffLine,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final opacities = [0.25, 0.45, 0.7, 0.45, 0.25];
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: opacities
            .map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Container(
                  height: 1.2,
                  color: color.withOpacity(o),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
