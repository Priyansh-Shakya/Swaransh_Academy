import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swaransh_academy/Core/fcm_service/firebase_options.dart';
import 'package:swaransh_academy/Core/fcm_service/service.dart';
import 'package:swaransh_academy/Core/local_storage/shared_pref.dart';
import 'package:swaransh_academy/app/my_app.dart';

class Bootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Hide ONLY the bottom navigation bar
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // 3. Force status bar background transparent & disable enforceNavigationBarContrast
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // Required for iOS support
        // Crucial for modern Android (Android 10+)
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    await dotenv.load(fileName: kIsWeb ? 'assets/env/web.env' : '.env');

    // Supabase init
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'],
    );
    debugPrint(
      "Supabase initilized ... Project URL: ${dotenv.env['SUPABASE_URL']}",
    );

    //* Initilize Firebase APP
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized');

    //* FCM Init
    //! ONLY Run when Platform is Not WEB
    if (!kIsWeb) {
      try {
        await FcmService.init();
      } catch (e, st) {
        debugPrint('FCM init failed (non-fatal): $e\n$st');
      }
    }

    // Initilize Local Shared pref
    await LocalStoragePref.initLocalStoragePref();
    // Firebase init (when needed)
    // Dependency injection
    // Error handlers
    // Logger setup

    //! CHECK ERROR ON WEB
    WidgetsFlutterBinding.ensureInitialized();

    // Catch errors in the Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('${details.stack}');
    };

    // Catch async errors outside Flutter widgets
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('ASYNC ERROR: $error');
      debugPrint('$stack');
      return true;
    };

    runApp(const ProviderScope(child: MyApp()));
  }
}
