//* function to identify who has birthday

import 'package:swaransh_academy/features/students/domain/student.dart';

bool hasBirthday(Student student) {
  final dob = student.dob;
  if (dob == null || dob.isEmpty) return false;

  final date = DateTime.tryParse(dob);
  if (date == null) return false;

  final now = DateTime.now();
  return date.month == now.month && date.day == now.day;
}
