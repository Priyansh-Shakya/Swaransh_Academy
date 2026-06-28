import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../Core/theme/app_theme.dart";
import "../features/navigation/router/app_router.dart";

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Swaransh Academy',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
