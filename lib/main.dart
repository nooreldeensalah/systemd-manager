import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/app.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.setup(level: LogLevel.info);

  final dbusService = DBusSystemdService();
  await dbusService.connect();

  runApp(
    ProviderScope(
      overrides: [
        systemdServiceProvider.overrideWithValue(dbusService),
        journalServiceProvider.overrideWithValue(JournalService()),
        analyzeServiceProvider.overrideWithValue(AnalyzeService()),
      ],
      child: const SystemdManagerApp(),
    ),
  );
}
