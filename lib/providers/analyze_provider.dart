import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:systemd_manager/models/boot_timings.dart';
import 'package:systemd_manager/services/services.dart';

part 'analyze_provider.g.dart';

@riverpod
AnalyzeService analyzeService(Ref ref) {
  throw UnimplementedError('analyzeService must be overridden');
}

@riverpod
Future<BootTimings> bootTimings(Ref ref) async {
  final service = ref.watch(analyzeServiceProvider);
  return service.getBootTimings();
}
