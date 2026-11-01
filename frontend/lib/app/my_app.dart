import "dart:async";

import "package:flutter/material.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:swaransh_academy/Core/fcm_service/service.dart";
import "package:swaransh_academy/Core/fcm_service/tokenProvider.dart";

import "../Core/theme/app_theme.dart";
import "../Core/widgets/connectivity_banner.dart";
import "../features/navigation/router/app_router.dart";

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = FcmService.onNotificationTap.listen((route) {
      if (mounted) {
        ref.read(appRouterProvider).go(route);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = FcmService.takePendingNotificationRoute();
      if (mounted && route != null) {
        ref.read(appRouterProvider).go(route);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
