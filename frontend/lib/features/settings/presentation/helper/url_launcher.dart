import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(BuildContext context, String url, String label) async {
  final uri = Uri.tryParse(url);

  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invalid $label link')));
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $label')));
    }
  }
}
