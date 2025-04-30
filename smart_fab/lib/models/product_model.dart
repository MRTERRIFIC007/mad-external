class ProductModel {
  final String id;
  final String name;
  final String description;
  final double manufacturingCost;
  final double sellingPrice;
  final double profitMargin;
  final List<String> materialIds;
  final List<String> processIds;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.manufacturingCost,
    required this.sellingPrice,
    required this.profitMargin,
    required this.materialIds,
    required this.processIds,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  double get profitPercentage => (profitMargin / manufacturingCost) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'manufacturingCost': manufacturingCost,
      'sellingPrice': sellingPrice,
      'profitMargin': profitMargin,
      'materialIds': materialIds,
      'processIds': processIds,
      'image': image,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      manufacturingCost: (map['manufacturingCost'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      profitMargin: (map['profitMargin'] as num).toDouble(),
      materialIds: List<String>.from(map['materialIds'] ?? []),
      processIds: List<String>.from(map['processIds'] ?? []),
      image: map['image'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? manufacturingCost,
    double? sellingPrice,
    double? profitMargin,
    List<String>? materialIds,
    List<String>? processIds,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      manufacturingCost: manufacturingCost ?? this.manufacturingCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      profitMargin: profitMargin ?? this.profitMargin,
      materialIds: materialIds ?? this.materialIds,
      processIds: processIds ?? this.processIds,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 