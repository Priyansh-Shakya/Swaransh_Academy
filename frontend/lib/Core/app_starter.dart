import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swaransh_academy/Core/local_storage/shared_pref.dart';
import 'package:swaransh_academy/app/my_app.dart';

class Bootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await dotenv.load(fileName: '.env');

    // Supabase init
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
    );
    debugPrint(
      "Supabase initilized ... Project URL: ${dotenv.env['SUPABASE_URL']}",
    );

    // Initilize Local Shared pref
    await LocalStoragePref.initLocalStoragePref();
    // Firebase init (when needed)
    // Dependency injection
    // Error handlers
    // Logger setup

    runApp(const ProviderScope(child: MyApp()));
  }
}
