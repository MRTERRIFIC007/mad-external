import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_fab/services/services.dart';

// Auth Service Provider
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

// Admin Status Provider
final isAdminProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAdmin;
});

// Material Service Provider
final materialServiceProvider = ChangeNotifierProvider<MaterialService>((ref) {
  return MaterialService();
});

// Process Service Provider
final processServiceProvider = ChangeNotifierProvider<ProcessService>((ref) {
  return ProcessService();
});

// Consumption Log Service Provider
final consumptionLogServiceProvider =
    ChangeNotifierProvider<ConsumptionLogService>((ref) {
  final materialService = ref.watch(materialServiceProvider);
  final processService = ref.watch(processServiceProvider);

  return ConsumptionLogService(
    materialService: materialService,
    processService: processService,
  );
});

// Report Service Provider
final reportServiceProvider = Provider<ReportService>((ref) {
  final consumptionLogService = ref.watch(consumptionLogServiceProvider);

  return ReportService(
    consumptionLogService: consumptionLogService,
  );
});

// Scanner Service Provider
final scannerServiceProvider = Provider<ScannerService>((ref) {
  final materialService = ref.watch(materialServiceProvider);

  return ScannerService(
    materialService: materialService,
  );
});

// Materials Provider
final materialsProvider = Provider((ref) {
  final materialService = ref.watch(materialServiceProvider);
  return materialService.materials;
});

// Low Stock Materials Provider
final lowStockMaterialsProvider = Provider((ref) {
  final materialService = ref.watch(materialServiceProvider);
  return materialService.lowStockMaterials;
});

// Processes Provider
final processesProvider = Provider((ref) {
  final processService = ref.watch(processServiceProvider);
  return processService.processes;
});

// Consumption Logs Provider
final consumptionLogsProvider = Provider((ref) {
  final consumptionLogService = ref.watch(consumptionLogServiceProvider);
  return consumptionLogService.logs;
});
