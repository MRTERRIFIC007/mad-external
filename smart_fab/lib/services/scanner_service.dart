import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/material_service.dart';

enum ScanResult {
  success,
  notFound,
  error,
}

class ScannerService {
  final MaterialService _materialService;

  ScannerService({required MaterialService materialService})
      : _materialService = materialService;

  // Handle scan result
  Future<Map<String, dynamic>> handleScan(String? barcode) async {
    if (barcode == null || barcode.isEmpty) {
     return {
        'result': ScanResult.error,
        'message': 'Invalid barcode data',
        'material': null,
      };
    }

    try {
      // Check if the scanned barcode matches any material
      final material = _materialService.getMaterialByQrCode(barcode);

      if (material != null) {
        return {
          'result': ScanResult.success,
          'message': 'Material found: ${material.name}',
          'material': material,
        };
      } else {
        return {
          'result': ScanResult.notFound,
          'message': 'No material found with code: $barcode',
          'material': null,
        };
      }
    } catch (e) {
      return {
        'result': ScanResult.error,
        'message': 'Error processing scan: $e',
        'material': null,
      };
    }
  }

  // Generate a QR code for a material
  String generateMaterialQrCode(MaterialModel material) {
  
    return material.id;
  }
} 