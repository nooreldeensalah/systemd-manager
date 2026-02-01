import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/app.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

final _log = Logger('main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.setup(level: LogLevel.info);

  _log.info('Starting Systemd Manager');

  _log.info('Initializing services...');
  final dbusService = DBusSystemdService();
  await dbusService.connect();

  final journalService = JournalService();
  final analyzeService = AnalyzeService();

  _log.info('Services initialized');

  runApp(
    ProviderScope(
      overrides: [
        systemdServiceProvider.overrideWithValue(dbusService),
        journalServiceProvider.overrideWithValue(journalService),
        analyzeServiceProvider.overrideWithValue(analyzeService),
      ],
      child: _AppLifecycleManager(
        onDispose: () async {
          _log.info('Disposing services...');
          await dbusService.dispose();
          _log.info('Services disposed');
        },
        child: const SystemdManagerApp(),
      ),
    ),
  );
}

class _AppLifecycleManager extends StatefulWidget {
  const _AppLifecycleManager({required this.child, required this.onDispose});

  final Widget child;
  final Future<void> Function() onDispose;

  @override
  State<_AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<_AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.onDispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      widget.onDispose();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
