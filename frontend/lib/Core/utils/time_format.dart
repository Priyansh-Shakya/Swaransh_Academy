String formatTime12Hour(String? value) {
  if (value == null || value.isEmpty) return value ?? '';

  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$',
  ).firstMatch(value.trim());
  if (match == null) return value;

  final hour24 = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour24 > 23 || minute > 59) return value;

  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}
