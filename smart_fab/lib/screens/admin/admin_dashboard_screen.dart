import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/screens/admin/materials_management_screen.dart';
import 'package:smart_fab/screens/admin/reports_screen.dart';
import 'package:smart_fab/screens/scanner/scanner_screen.dart';
import 'package:smart_fab/widgets/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialService = ref.watch(materialServiceProvider);
    final processService = ref.watch(processServiceProvider);
    final consumptionLogService = ref.watch(consumptionLogServiceProvider);
    final materials = ref.watch(materialsProvider);
    final lowStockMaterials = ref.watch(lowStockMaterialsProvider);
    final logs = ref.watch(consumptionLogsProvider);
    final processes = ref.watch(processesProvider);
    
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    // Calculate total inventory value
    final totalInventoryValue = materials.fold<double>(
      0,
      (sum, material) => sum + (material.stockQuantity * material.unitCost),
    );
    
    // Calculate today's usage
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todayLogs = consumptionLogService.getLogsByDateRange(startOfDay, endOfDay);
    final todayUsage = todayLogs.fold<double>(
      0,
      (sum, log) => sum + log.materialCost,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                try {
                  await materialService.syncWithCloud();
                  await processService.syncWithCloud();
                  await consumptionLogService.syncWithCloud();
                } catch (e) {
                  debugPrint('Error syncing data: $e');
                }
              },
              tooltip: 'Sync Data',
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'SmartFab Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Materials'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterialsManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Processes'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to processes screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan Material'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: materialService.isLoading || processService.isLoading || consumptionLogService.isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: () async {
                await materialService.fetchMaterials(forceRefresh: true);
                await processService.fetchProcesses(forceRefresh: true);
                await consumptionLogService.fetchLogs(forceRefresh: true);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    const Text(
                      'Welcome to SmartFab Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening today',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Dashboard Cards
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        DashboardCard(
                          title: 'Inventory',
                          value: currencyFormat.format(totalInventoryValue),
                          subtitle: '${materials.length} materials',
                          icon: Icons.inventory_2,
                          type: AppConstants.inventoryCard,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MaterialsManagementScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          title: 'Today\'s Usage',
                          value: currencyFormat.format(todayUsage),
                          subtitle: '${todayLogs.length} logs today',
                          icon: Icons.assessment,
                          type: AppConstants.usageCard,
                          onTap: () {
                            // Navigate to logs screen
                          },
                        ),
                        DashboardCard(
                          title: 'Processes',
                          value: processes.length.toString(),
                          subtitle: 'Manufacturing processes',
                          icon: Icons.settings,
                          type: AppConstants.costingCard,
                          onTap: () {
                            // Navigate to processes screen
                          },
                        ),
                        DashboardCard(
                          title: 'Low Stock',
                          value: lowStockMaterials.length.toString(),
                          subtitle: 'Items need attention',
                          icon: Icons.warning_amber,
                          type: AppConstants.alertsCard,
                          onTap: () {
                            // Navigate to low stock screen
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Low Stock Alerts
                    const Text(
                      'Low Stock Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    lowStockMaterials.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No low stock alerts',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lowStockMaterials.length,
                            itemBuilder: (context, index) {
                              final material = lowStockMaterials[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(material.name),
                                  subtitle: Text(
                                    '${material.stockQuantity} ${material.unitDisplay} left (Min: ${material.minimumStockLevel} ${material.unitDisplay})',
                                  ),
                                  leading: const Icon(
                                    Icons.warning_amber,
                                    color: AppTheme.warningColor,
                                  ),
                                  trailing: StockStatusBadge(
                                    stockQuantity: material.stockQuantity,
                                    minimumStockLevel: material.minimumStockLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                    
                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    logs.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No recent activity',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: logs.length > 5 ? 5 : logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[logs.length - 1 - index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(log.material?.name ?? 'Unknown Material'),
                                  subtitle: Text(
                                    'Used ${log.quantity} ${log.material?.unitDisplay ?? ''} • ${DateFormat('MMM dd, HH:mm').format(log.createdAt)}',
                                  ),
                                  trailing: Text(
                                    currencyFormat.format(log.materialCost),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.qr_code_scanner),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScannerScreen(),
            ),
          );
        },
      ),
    );
  }
} 