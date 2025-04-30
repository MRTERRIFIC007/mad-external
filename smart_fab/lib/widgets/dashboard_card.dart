import 'package:flutter/material.dart';
import 'package:smart_fab/core/app_constants.dart';
import 'package:smart_fab/core/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final String type;
  final VoidCallback onTap;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color iconColor;

    switch (type) {
      case AppConstants.inventoryCard:
        cardColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        break;
      case AppConstants.costingCard:
        cardColor = Colors.green.shade50;
        iconColor = Colors.green;
        break;
      case AppConstants.usageCard:
        cardColor = Colors.purple.shade50;
        iconColor = Colors.purple;
        break;
      case AppConstants.alertsCard:
        cardColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        break;
      default:
        cardColor = Colors.grey.shade50;
        iconColor = Colors.grey;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 