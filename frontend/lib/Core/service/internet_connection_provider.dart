import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final internetConnectionStatusProvider = StreamProvider<bool>((ref) async* {
  final connection = InternetConnection();

  yield await connection.hasInternetAccess;

  await for (final status in connection.onStatusChange) {
    yield status == InternetStatus.connected;
  }
});
