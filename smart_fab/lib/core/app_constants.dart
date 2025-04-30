import 'package:intl/intl.dart';

class AppConstants {
  // App name
  static const String appName = 'SmartFab';

  // Collection names in Firestore
  static const String materialsCollection = 'materials';
  static const String processesCollection = 'processes';
  static const String consumptionLogsCollection = 'consumptionLogs';
  static const String productsCollection = 'products';

  // Hive box names
  static const String materialsBox = 'materials';
  static const String processesBox = 'processes';
  static const String consumptionLogsBox = 'consumptionLogs';
  static const String userBox = 'users';

  // User related constants
  static const String currentUserKey = 'currentUser';
  static const String adminRole = 'admin';

  // Default margins
  static const double defaultMargin = 0.3; // 30% margin for pricing suggestions

  // Dashboard card types
  static const String inventoryCard = 'inventory';
  static const String costingCard = 'costing';
  static const String usageCard = 'usage';
  static const String alertsCard = 'alerts';

  // Currency formatter
  static final NumberFormat currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  // Helper method for formatting currency
  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }
}
