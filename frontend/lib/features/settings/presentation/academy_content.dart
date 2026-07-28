/// All human-readable content for the Settings / About section lives here.
/// Change names, bios, contact details, and photo URLs in this one file
/// without touching any widget code.
class AcademyContent {
  AcademyContent._();

  // ---- Academy ----
  static const String name = 'Swaransh Academy of Music & Art';
  static const String tagline =
      'Nurturing Talent, Inspiring Expression, Enriching Lives';
  static const String about = '''
Swaransh Academy of Music & Art is a dedicated centre for music, dance, acting, and audio/video production based in Bhopal, Madhya Pradesh. Founded with a passion for the arts, we offer structured learning in a warm, encouraging environment suited to students of all ages and backgrounds.

Our programmes span classical and contemporary forms, with experienced faculty guiding students from their first notes to professional-level performance.
''';

  //* Set to a Supabase Storage URL once the academy photo is uploaded.
  static const String? academyImageUrl =
      'http://127.0.0.1:54321/storage/v1/object/public/admin-photos/WhatsApp%20Image%202026-07-27%20at%2010.34.15%20AM.jpeg';

  // ---- Contact ----
  static const String contactEmail = 'swaranshacademy@gmail.com';
  static const String contactPhone = '+91 XXXXX XXXXX'; // replace

  // ---- Team ----
  static const List<TeamMember> team = [
    TeamMember(
      name: 'Prof. Ravi Shakya', // replace
      position: 'Chairman & Founder',
      bio:
          'A lifelong devotion to music and the belief that every person '
          'carries a melody waiting to be discovered — that vision is the '
          'heart of Swaransh Academy.',
      photoUrl:
          'http://127.0.0.1:54321/storage/v1/object/public/admin-photos/IMG_20160815_090735.jpg', // replace with Supabase Storage URL when ready
    ),
    TeamMember(
      name: 'Swaransh Shakya', // replace
      position: 'Managing Director',
      bio:
          'Overseeing day-to-day operations and curriculum development, '
          'bringing both professional rigour and creative energy to the '
          'academy\'s growth.',
      photoUrl:
          'http://127.0.0.1:54321/storage/v1/object/public/admin-photos/swaransh.jpeg',
    ),
  ];

  //! Social Media

  // ---- Social Media ----
  static const List<SocialLink> socials = [
    SocialLink(
      label: 'Instagram',
      handle: '@swaranshacademy', // replace
      url: 'https://instagram.com/swaranshacademy', // replace
      icon: 'instagram',
    ),
    SocialLink(
      label: 'YouTube',
      handle: 'Swaransh Academy', // replace
      url: 'https://youtube.com/@swaranshacademy', // replace
      icon: 'youtube',
    ),
    SocialLink(
      label: 'Facebook',
      handle: 'Swaransh Academy', // replace
      url: 'https://facebook.com/swaranshacademy', // replace
      icon: 'facebook',
    ),
  ];
}

class TeamMember {
  const TeamMember({
    required this.name,
    required this.position,
    required this.bio,
    this.photoUrl,
  });

  final String name;
  final String position;
  final String bio;
  final String? photoUrl;
}

class SocialLink {
  const SocialLink({
    required this.label,
    required this.handle,
    required this.url,
    required this.icon,
  });

  final String label;
  final String handle;
  final String url;
  final String icon; // used to pick icon below
}
