import 'package:smart_fab/models/material_model.dart';

/// Helper class for working with UnitType enum values
class UnitTypeHelper {
  /// Get a UnitType enum value by its name
  static UnitType getByName(String name) {
    switch (name) {
      case 'kg':
        return UnitType.kg;
      case 'kilograms':
        return UnitType.kilograms;
      case 'liter':
        return UnitType.liter;
      case 'piece':
        return UnitType.piece;
      case 'pieces':
        return UnitType.pieces;
      case 'meter':
        return UnitType.meter;
      case 'meters':
        return UnitType.meters;
      case 'gram':
        return UnitType.gram;
      case 'milliliter':
        return UnitType.milliliter;
      case 'squareFeet':
        return UnitType.squareFeet;
      default:
        return UnitType.piece;
    }
  }

  /// Get all available unit types as a list
  static List<UnitType> get allUnitTypes => UnitType.values;
} 