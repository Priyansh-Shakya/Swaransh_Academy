import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/theme/app_colors.dart';
import 'package:swaransh_academy/Core/theme/app_typography.dart';

void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.staffLine,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(message, style: AppTypography.caption.copyWith(color: AppColors.textOnNavy)),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 2), entry.remove);
}
