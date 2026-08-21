class AppOption {
  final String value; // API / DB value
  final String label; // Human-readable UI value

  const AppOption({required this.value, required this.label});
}

class AppOptions {
  AppOptions._();

  static const gender = <AppOption>[
    AppOption(value: 'male', label: 'Male'),
    AppOption(value: 'female', label: 'Female'),
    AppOption(value: 'non_binary', label: 'Non-binary'),
  ];

  static const educationQualification = <AppOption>[
    AppOption(value: 'primary_school', label: 'Primary School'),
    AppOption(value: 'high_school', label: 'High School'),
    AppOption(value: 'bachelors', label: 'Bachelors'),
    AppOption(value: 'masters', label: 'Masters'),
  ];

  static const department = <AppOption>[
    AppOption(value: 'music', label: 'Music'),
    AppOption(value: 'dance', label: 'Dance'),
    AppOption(value: 'acting', label: 'Acting'),
    AppOption(
      value: 'music_video_production',
      label: 'Music / Video Production',
    ),
    AppOption(value: 'other', label: 'Other'),
  ];

  static const admissionType = <AppOption>[
    AppOption(value: 'regular', label: 'Regular'),
    AppOption(value: 'band_training', label: 'Band Training'),
    AppOption(value: 'summer_camp', label: 'Summer Camp'),
    AppOption(value: 'custom', label: 'Custom'),
  ];

  static const learningMode = <AppOption>[
    AppOption(value: 'online', label: 'Online'),
    AppOption(value: 'offline', label: 'Offline'),
    AppOption(value: 'hybrid', label: 'Hybrid'),
  ];

  static const batch = <AppOption>[
    AppOption(value: 'morning', label: 'Morning'),
    AppOption(value: 'evening', label: 'Evening'),
  ];

  static const feeType = <AppOption>[
    AppOption(value: 'monthly', label: 'Monthly'),
    AppOption(value: 'quarterly', label: 'Quarterly'),
    AppOption(value: 'half_yearly', label: 'Half Yearly'),
    AppOption(value: 'yearly', label: 'Yearly'),
  ];

  static const paymentMode = <AppOption>[
    AppOption(value: 'upi', label: 'UPI'),
    AppOption(value: 'cash', label: 'Cash'),
    AppOption(value: 'card', label: 'Card'),
    AppOption(value: 'bank_transfer', label: 'Bank Transfer'),
    AppOption(value: 'other', label: 'Other'),
  ];

  static const paymentCategory = <AppOption>[ 
    AppOption(value: 'fee', label: 'Fee'),
    AppOption(value: 'admission', label: 'Admission'),
    AppOption(value: 'other', label: 'Other'),
  ];

  static const courseTag = <AppOption>[
    AppOption(value: 'vocal', label: 'Vocal'),
    AppOption(value: 'instrumental', label: 'Instrumental'),
  ];

  static const admissionStatus = <AppOption>[
    AppOption(value: 'pending', label: 'Pending'),
    AppOption(value: 'approved', label: 'Approved'),
    AppOption(value: 'declined', label: 'Declined'),
  ];
}
