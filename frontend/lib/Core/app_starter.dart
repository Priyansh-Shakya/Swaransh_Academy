import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:swaransh_academy/app/my_app.dart";

class Bootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");

    // DB init
    // Firebase init
    // Supabase init
    // Dependency injection
    // Error handlers
    // Logger setup

    runApp(const ProviderScope(child: MyApp()));
  }
}
