import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/theme/app_spacing.dart';
import 'package:swaransh_academy/Core/theme/app_typography.dart';

class AdminCodeDialog extends StatefulWidget {
  const AdminCodeDialog({super.key});

  @override
  State<AdminCodeDialog> createState() => _AdminCodeDialogState();
}

class _AdminCodeDialogState extends State<AdminCodeDialog> {
  final codeCtrl = TextEditingController();
  bool _obscureCode = true;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the admin access code to continue.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: codeCtrl,
            obscureText: _obscureCode,
            decoration: InputDecoration(
              labelText: 'Admin Code',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCode
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCode = !_obscureCode;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, codeCtrl.text.trim());
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
