/// Shared spacing/radius scale. Pull from here instead of magic numbers
/// scattered per screen - keeps every feature visually consistent even
/// when built in separate sessions.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}
