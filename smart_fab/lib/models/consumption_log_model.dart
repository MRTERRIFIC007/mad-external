import 'package:smart_fab/models/material_model.dart';
import 'package:smart_fab/models/process_model.dart';

class ConsumptionLogModel {
  final String id;
  final String materialId;
  final String processId;
  final double quantity;
  final String? productName;
  final double? processDurationHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // For local use (not stored in Firebase)
  final MaterialModel? material;
  final ProcessModel? process;

  ConsumptionLogModel({
    required this.id,
    required this.materialId,
    required this.processId,
    required this.quantity,
    this.productName,
    this.processDurationHours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.material,
    this.process,
  });

  // Calculate material cost
  double get materialCost => material != null 
      ? material!.unitCost * quantity 
      : 0.0;

  // Calculate processing cost
  double get processingCost => process != null && processDurationHours != null
      ? process!.totalCostPerHour * processDurationHours!
      : 0.0;

  // Calculate total manufacturing cost
  double get totalManufacturingCost => materialCost + processingCost;

  // Calculate suggested selling price with 30% margin
  double get suggestedSellingPrice => totalManufacturingCost * 1.3;

  // Calculate profit margin
  double get profitMargin => suggestedSellingPrice - totalManufacturingCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialId': materialId,
      'processId': processId,
      'quantity': quantity,
      'productName': productName,
      'processDurationHours': processDurationHours,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ConsumptionLogModel.fromMap(
    Map<String, dynamic> map, {
    MaterialModel? material,
    ProcessModel? process,
  }) {
    return ConsumptionLogModel(
      id: map['id'] ?? '',
      materialId: map['materialId'] ?? '',
      processId: map['processId'] ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      productName: map['productName'],
      processDurationHours: map['processDurationHours'] != null 
          ? (map['processDurationHours'] as num).toDouble() 
          : null,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      material: material,
      process: process,
    );
  }

  ConsumptionLogModel copyWith({
    String? id,
    String? materialId,
    String? processId,
    double? quantity,
    String? productName,
    double? processDurationHours,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    MaterialModel? material,
    ProcessModel? process,
  }) {
    return ConsumptionLogModel(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      processId: processId ?? this.processId,
      quantity: quantity ?? this.quantity,
      productName: productName ?? this.productName,
      processDurationHours: processDurationHours ?? this.processDurationHours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      material: material ?? this.material,
      process: process ?? this.process,
    );
  }
} 