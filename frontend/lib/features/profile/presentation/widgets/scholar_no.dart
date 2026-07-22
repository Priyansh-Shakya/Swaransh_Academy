import 'package:flutter/material.dart';
import 'package:swaransh_academy/Core/local_storage/shared_pref.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

/// Shown when a user account is linked to multiple student records
/// (siblings sharing one parent email). Lets them pick the right one
/// by entering the scholar number printed on that student's admission card.
class ScholarNumberDialog extends StatefulWidget {
  const ScholarNumberDialog({
    super.key,
    required this.candidates,
    required this.onSelected,
  });

  /// All sibling student records already fetched — matching happens
  /// locally against this list, no extra API call.
  final List<Student> candidates;

  /// Called with the resolved student's id once a valid scholar number
  /// is entered.
  final void Function(int studentId) onSelected;

  @override
  State<ScholarNumberDialog> createState() => _ScholarNumberDialogState();
}

class _ScholarNumberDialogState extends State<ScholarNumberDialog> {
  final _codeCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final entered = _codeCtrl.text.trim();

    if (entered.isEmpty) {
      setState(() => _errorText = 'Please enter a scholar number.');
      return;
    }

    final match = widget.candidates
        .where(
          (s) =>
              (s.scholarNo ?? '').trim().toLowerCase() == entered.toLowerCase(),
        )
        .firstOrNull;

    if (match == null) {
      setState(() => _errorText = "No student found with that scholar number.");
      return;
    }

    widget.onSelected(match.id!);

    //* Saving Student Id to shared pref
    debugPrint("Setting Student to shared pref...");
    await LocalStoragePref.setSiblingStudentId(match.id!);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Whose profile is this?'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "We found more than one student profile linked to this account "
              "(usually siblings sharing a parent email). Please enter the Scholar Number of the student whose profile you want to open.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Scholar Number',
                prefixIcon: const Icon(Icons.badge_outlined),
                errorText: _errorText,
                helperText: "Ask the academy (Admin) if you don't have it.",
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
