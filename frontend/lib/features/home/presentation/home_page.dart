import 'package:flutter/material.dart';

/// Placeholder. Real content (course catalogue, starter/about content)
/// comes in the Courses feature chunk.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swaransh Academy')),
      body: const Center(child: Text('Home / Courses - coming next')),
    );
  }
}
