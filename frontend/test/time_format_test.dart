import 'package:flutter_test/flutter_test.dart';
import 'package:swaransh_academy/Core/utils/time_format.dart';

void main() {
  group('formatTime12Hour', () {
    test('formats midnight and afternoon times', () {
      expect(formatTime12Hour('00:05:00'), '12:05 AM');
      expect(formatTime12Hour('12:00:00'), '12:00 PM');
      expect(formatTime12Hour('13:30:00'), '1:30 PM');
      expect(formatTime12Hour('23:59'), '11:59 PM');
    });

    test('preserves empty and invalid values', () {
      expect(formatTime12Hour(''), '');
      expect(formatTime12Hour('not-a-time'), 'not-a-time');
      expect(formatTime12Hour('24:00:00'), '24:00:00');
    });
  });
}
