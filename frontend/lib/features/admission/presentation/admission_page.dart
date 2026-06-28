import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admission_prefill.dart';

/// Placeholder. Real form (multi-step: form -> T&C -> payment) comes in the
/// Admission feature chunk. For now this just proves the pre-fill handoff
/// from CourseDetailPage's "Apply Now" actually works end-to-end.
class AdmissionPage extends ConsumerWidget {
  const AdmissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefill = ref.watch(admissionPrefillProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admission')),
      body: Center(
        child: prefill == null
            ? const Text('Admission form / review - coming soon')
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pre-filled from course tap:'),
                    const SizedBox(height: 8),
                    Text('Department: ${prefill.department}'),
                    Text('Subject: ${prefill.subject}'),
                    const SizedBox(height: 16),
                    const Text('(Real form fields go here)'),
                  ],
                ),
              ),
      ),
    );
  }
}
