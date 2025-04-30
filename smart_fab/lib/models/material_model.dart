import 'package:hive/hive.dart';

// Re-define the enum with named values to ensure they match the references
enum UnitType {
  kg('kg'),
  kilograms('kilograms'),
  liter('liter'),
  piece('piece'),
  pieces('pieces'),
  meter('meter'),
  meters('meters'),
  gram('gram'),
  milliliter('milliliter'),
  squareFeet('squareFeet');

  const UnitType(this.value);
  final String value;
  
  @override
  String toString() => value;
}

class MaterialModel {
  final String id;
  final String name;
  final String qrCode;
  final double unitCost;
  final UnitType unitType;
  final double stockQuantity;
  final double minimumStockLevel;
  final String? description;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaterialModel({
    required this.id,
    required this.name,
    required this.qrCode,
    required this.unitCost,
    required this.unitType,
    required this.stockQuantity,
    required this.minimumStockLevel,
    this.description,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= minimumStockLevel;

  String get unitDisplay => unitType.value;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'qrCode': qrCode,
      'unitCost': unitCost,
      'unitType': unitType.value,
      'stockQuantity': stockQuantity,
      'minimumStockLevel': minimumStockLevel,
      'description': description,
      'image': image,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      qrCode: map['qrCode'] ?? '',
      unitCost: (map['unitCost'] as num).toDouble(),
      unitType: UnitType.values.firstWhere(
        (e) => e.value == map['unitType'],
        orElse: () => UnitType.piece,
      ),
      stockQuantity: (map['stockQuantity'] as num).toDouble(),
      minimumStockLevel: (map['minimumStockLevel'] as num).toDouble(),
      description: map['description'],
      image: map['image'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  MaterialModel copyWith({
    String? id,
    String? name,
    String? qrCode,
    double? unitCost,
    UnitType? unitType,
    double? stockQuantity,
    double? minimumStockLevel,
    String? description,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      qrCode: qrCode ?? this.qrCode,
      unitCost: unitCost ?? this.unitCost,
      unitType: unitType ?? this.unitType,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      description: description ?? this.description,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 