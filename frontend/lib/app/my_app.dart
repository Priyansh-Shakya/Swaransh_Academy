import "package:flutter/material.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:swaransh_academy/Core/fcm_service/tokenProvider.dart";

import "../Core/theme/app_theme.dart";
import "../features/navigation/router/app_router.dart";

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 THIS LINE WAKES UP & ACTIVATES THE FCM PROVIDER
    ref.listen(fcmInitProvider, (_, __) {});
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      locale: const Locale('en', 'IN'),
      supportedLocales: const [Locale('en', 'IN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'Swaransh Academy',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
