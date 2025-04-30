import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/consumption_log_service.dart';
import 'package:smart_fab/utils/export_utils.dart';

class ReportService {
  final ConsumptionLogService _consumptionLogService;

  ReportService({required ConsumptionLogService consumptionLogService})
      : _consumptionLogService = consumptionLogService;

  // Generate consumption logs report as PDF
  Future<File> generateConsumptionLogsPdf({
    required DateTime startDate,
    required DateTime endDate,
    String? materialId,
    String? productName,
  }) async {
    List<ConsumptionLogModel> logs;

    if (materialId != null) {
      logs = _consumptionLogService.getLogsByMaterial(materialId);
    } else if (productName != null) {
      logs = _consumptionLogService.getLogsByProduct(productName);
    } else {
      logs = _consumptionLogService.getLogsByDateRange(startDate, endDate);
    }

    // Filter logs by date range
    logs = logs.where((log) => 
      log.createdAt.isAfter(startDate) && log.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SmartFab Consumption Log Report'),
          ),
          pw.Paragraph(
            text: 'Report Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
          ),
          pw.Paragraph(
            text: 'Total Records: ${logs.length}',
          ),
          pw.Paragraph(
            text: 'Total Material Cost: ${currencyFormat.format(_consumptionLogService.calculateTotalMaterialCost(startDate, endDate))}',
          ),
          pw.Paragraph(
            text: 'Total Processing Cost: ${currencyFormat.format(_consumptionLogService.calculateTotalProcessingCost(startDate, endDate))}',
          ),
          pw.Paragraph(
            text: 'Total Manufacturing Cost: ${currencyFormat.format(_consumptionLogService.calculateTotalManufacturingCost(startDate, endDate))}',
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 30,
            cellHeight: 30,
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              color: PdfColors.black,
            ),
            headers: [
              'Date',
              'Material',
              'Quantity',
              'Process',
              'Duration (hrs)',
              'Material Cost',
              'Process Cost',
              'Total Cost',
            ],
            data: logs.map((log) {
              return [
                dateFormat.format(log.createdAt),
                log.material?.name ?? 'Unknown',
                '${log.quantity} ${log.material?.unitDisplay ?? ''}',
                log.process?.name ?? 'Unknown',
                log.processDurationHours?.toString() ?? 'N/A',
                currencyFormat.format(log.materialCost),
                currencyFormat.format(log.processingCost),
                currencyFormat.format(log.totalManufacturingCost),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      final filePath = await ExportUtils.getTemporaryFilePath('consumption_report.pdf');
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('Error saving PDF file: $e');
      rethrow;
    }
  }

  // Generate materials inventory report as PDF
  Future<File> generateInventoryReportPdf(List<MaterialModel> materials) async {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SmartFab Inventory Report'),
          ),
          pw.Paragraph(
            text: 'Report Generated: ${dateFormat.format(DateTime.now())}',
          ),
          pw.Paragraph(
            text: 'Total Materials: ${materials.length}',
          ),
          pw.Paragraph(
            text: 'Low Stock Items: ${materials.where((m) => m.isLowStock).length}',
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 30,
            cellHeight: 30,
            headerStyle: pw.TextStyle(
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(
              color: PdfColors.black,
            ),
            headers: [
              'Material',
              'QR Code',
              'Unit Cost',
              'Current Stock',
              'Min. Stock',
              'Status',
            ],
            data: materials.map((material) {
              return [
                material.name,
                material.qrCode,
                currencyFormat.format(material.unitCost),
                '${material.stockQuantity} ${material.unitDisplay}',
                '${material.minimumStockLevel} ${material.unitDisplay}',
                material.isLowStock ? 'LOW STOCK' : 'OK',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      final filePath = await ExportUtils.getTemporaryFilePath('inventory_report.pdf');
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('Error saving PDF file: $e');
      rethrow;
    }
  }

  // Generate consumption logs as CSV
  Future<File> generateConsumptionLogsCsv({
    required DateTime startDate,
    required DateTime endDate,
    String? materialId,
    String? productName,
  }) async {
    List<ConsumptionLogModel> logs;

    if (materialId != null) {
      logs = _consumptionLogService.getLogsByMaterial(materialId);
    } else if (productName != null) {
      logs = _consumptionLogService.getLogsByProduct(productName);
    } else {
      logs = _consumptionLogService.getLogsByDateRange(startDate, endDate);
    }

    // Filter logs by date range
    logs = logs.where((log) => 
      log.createdAt.isAfter(startDate) && log.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    final List<List<dynamic>> rows = [];
    
    // Header row
    rows.add([
      'ID',
      'Date',
      'Time',
      'Material ID',
      'Material Name',
      'Quantity',
      'Unit',
      'Unit Cost',
      'Material Cost',
      'Process ID',
      'Process Name',
      'Duration (hrs)',
      'Process Cost/hr',
      'Process Cost',
      'Total Cost',
      'Product Name',
      'Notes'
    ]);

    // Data rows
    for (final log in logs) {
      rows.add([
        log.id,
        dateFormat.format(log.createdAt),
        timeFormat.format(log.createdAt),
        log.materialId,
        log.material?.name ?? 'Unknown',
        log.quantity,
        log.material?.unitDisplay ?? '',
        log.material?.unitCost ?? 0.0,
        log.materialCost,
        log.processId,
        log.process?.name ?? 'Unknown',
        log.processDurationHours ?? 0.0,
        log.process?.totalCostPerHour ?? 0.0,
        log.processingCost,
        log.totalManufacturingCost,
        log.productName ?? '',
        log.notes ?? '',
      ]);
    }

    try {
      final csvData = const ListToCsvConverter().convert(rows);
      final filePath = await ExportUtils.getTemporaryFilePath('consumption_report.csv');
      final file = File(filePath);
      await file.writeAsString(csvData);
      return file;
    } catch (e) {
      debugPrint('Error saving CSV file: $e');
      rethrow;
    }
  }

  // Generate inventory report as CSV
  Future<File> generateInventoryCsv(List<MaterialModel> materials) async {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final List<List<dynamic>> rows = [];
    
    // Header row
    rows.add([
      'ID',
      'Name',
      'QR Code',
      'Unit Cost',
      'Unit Type',
      'Current Stock',
      'Min Stock',
      'Stock Status',
      'Description',
      'Last Updated'
    ]);

    // Data rows
    for (final material in materials) {
      rows.add([
        material.id,
        material.name,
        material.qrCode,
        material.unitCost,
        material.unitDisplay,
        material.stockQuantity,
        material.minimumStockLevel,
        material.isLowStock ? 'LOW STOCK' : 'OK',
        material.description ?? '',
        dateFormat.format(material.updatedAt),
      ]);
    }

    try {
      final csvData = const ListToCsvConverter().convert(rows);
      final filePath = await ExportUtils.getTemporaryFilePath('inventory_report.csv');
      final file = File(filePath);
      await file.writeAsString(csvData);
      return file;
    } catch (e) {
      debugPrint('Error saving CSV file: $e');
      rethrow;
    }
  }

  // Share a report file
  Future<void> shareReportFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }
} 