import 'package:flutter/material.dart';
import 'package:smart_fab/core/app_theme.dart';

class StockStatusBadge extends StatelessWidget {
  final double stockQuantity;
  final double minimumStockLevel;

  const StockStatusBadge({
    Key? key,
    required this.stockQuantity,
    required this.minimumStockLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowStock = stockQuantity <= minimumStockLevel;
    final isOutOfStock = stockQuantity <= 0;

    Color badgeColor = AppTheme.inStockColor;
    String badgeText = 'In Stock';

    if (isOutOfStock) {
      badgeColor = AppTheme.outOfStockColor;
      badgeText = 'Out of Stock';
    } else if (isLowStock) {
      badgeColor = AppTheme.lowStockColor;
      badgeText = 'Low Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
} 