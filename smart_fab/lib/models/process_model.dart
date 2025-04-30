class ProcessModel {
  final String id;
  final String name;
  final String description;
  final double laborCostPerHour;
  final double energyCostPerHour;
  final double otherCostsPerHour;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProcessModel({
    required this.id,
    required this.name,
    required this.description,
    required this.laborCostPerHour,
    required this.energyCostPerHour,
    required this.otherCostsPerHour,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalCostPerHour =>
      laborCostPerHour + energyCostPerHour + otherCostsPerHour;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'laborCostPerHour': laborCostPerHour,
      'energyCostPerHour': energyCostPerHour,
      'otherCostsPerHour': otherCostsPerHour,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProcessModel.fromMap(Map<String, dynamic> map) {
    return ProcessModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      laborCostPerHour: (map['laborCostPerHour'] as num).toDouble(),
      energyCostPerHour: (map['energyCostPerHour'] as num).toDouble(),
      otherCostsPerHour: (map['otherCostsPerHour'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ProcessModel copyWith({
    String? id,
    String? name,
    String? description,
    double? laborCostPerHour,
    double? energyCostPerHour,
    double? otherCostsPerHour,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProcessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      laborCostPerHour: laborCostPerHour ?? this.laborCostPerHour,
      energyCostPerHour: energyCostPerHour ?? this.energyCostPerHour,
      otherCostsPerHour: otherCostsPerHour ?? this.otherCostsPerHour,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 