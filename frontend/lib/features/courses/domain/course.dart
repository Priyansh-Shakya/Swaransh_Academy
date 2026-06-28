/// Mirrors components.schemas.Course in the OpenAPI contract.
/// Keep field names identical to the contract - no renaming for "nicer" Dart
/// style, since that's what makes JSON mapping mechanical instead of error-prone.
class Course {
  const Course({
    required this.id,
    required this.courseName,
    required this.duration,
    required this.fees,
    required this.mode,
    required this.tag,
    required this.mapsToDepartment,
    required this.mapsToSubject,
    this.imageUrl,
  });

  final int id;
  final String courseName;
  final String duration;
  final double fees;
  final String mode; // Online | Offline | Hybrid
  final String tag; // Instrumental | Vocal
  final String mapsToDepartment; // Department enum value, used for admission pre-fill
  final String mapsToSubject; // exact subject value, used for admission pre-fill
  final String? imageUrl; // Supabase Storage public URL, nullable until admin uploads one

  Course copyWith({
    String? courseName,
    String? duration,
    double? fees,
    String? mode,
    String? tag,
    String? mapsToDepartment,
    String? mapsToSubject,
    String? imageUrl,
  }) {
    return Course(
      id: id,
      courseName: courseName ?? this.courseName,
      duration: duration ?? this.duration,
      fees: fees ?? this.fees,
      mode: mode ?? this.mode,
      tag: tag ?? this.tag,
      mapsToDepartment: mapsToDepartment ?? this.mapsToDepartment,
      mapsToSubject: mapsToSubject ?? this.mapsToSubject,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as int,
        courseName: json['course_name'] as String,
        duration: json['duration'] as String,
        fees: (json['fees'] as num).toDouble(),
        mode: json['mode'] as String,
        tag: json['tag'] as String,
        mapsToDepartment: json['maps_to_department'] as String,
        mapsToSubject: json['maps_to_subject'] as String,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_name': courseName,
        'duration': duration,
        'fees': fees,
        'mode': mode,
        'tag': tag,
        'maps_to_department': mapsToDepartment,
        'maps_to_subject': mapsToSubject,
        'image_url': imageUrl,
      };
}
