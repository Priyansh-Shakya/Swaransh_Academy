import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swaransh_academy/Core/service/internet_connection_provider.dart';
import 'package:swaransh_academy/Core/widgets/connectivity_banner.dart';

void main() {
  testWidgets('shows the offline banner when internet is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internetConnectionStatusProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => ConnectivityBanner(child: child!),
          home: const Scaffold(body: Text('Feature page')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Feature page'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('hides the offline banner when internet is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internetConnectionStatusProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => ConnectivityBanner(child: child!),
          home: const Scaffold(body: Text('Feature page')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('Feature page'), findsOneWidget);
  });
}
