import 'package:flutter/material.dart';

/// Placeholder. Real content (optimistic-update editing pattern) comes
/// in the Profile feature chunk.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: Text('Profile - coming soon')),
    );
  }
}
