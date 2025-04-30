import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/widgets/widgets.dart';

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialService = ref.watch(materialServiceProvider);
    final consumptionLogService = ref.watch(consumptionLogServiceProvider);
    final currentUser = ref.watch(currentUserProvider);
    final materials = ref.watch(materialsProvider);
    final logs = ref.watch(consumptionLogsProvider);
    
    // Get operator's logs only
    final operatorLogs = logs
        .where((log) => log.userId == currentUser?.id)
        .toList();
    
    // Calculate today's logs
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todayLogs = operatorLogs
        .where((log) => log.createdAt.isAfter(startOfDay) && log.createdAt.isBefore(endOfDay))
        .toList();
    
    // Format currency
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await materialService.syncWithCloud();
              await consumptionLogService.syncWithCloud();
            },
            tooltip: 'Sync Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Authentication is bypassed. Staying logged in as admin.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Logout (Disabled)',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser?.name ?? 'Operator User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser?.email ?? 'operator@example.com',
                    style: const TextStyle(
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
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan Materials'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to scanner screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('My Activity'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to operator logs screen
              },
            ),
          ],
        ),
      ),
      body: materialService.isLoading || consumptionLogService.isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: () async {
                await materialService.fetchMaterials(forceRefresh: true);
                await consumptionLogService.fetchLogs(forceRefresh: true);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    Text(
                      'Welcome, ${currentUser?.name ?? 'Operator'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s your activity for today',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today\'s Scans',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  todayLogs.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Materials processed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Usage',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(
                                    todayLogs.fold<double>(
                                      0,
                                      (sum, log) => sum + log.materialCost,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Material cost',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Today's Activity
                    const Text(
                      'Today\'s Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    todayLogs.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No activity recorded today',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: todayLogs.length,
                            itemBuilder: (context, index) {
                              final log = todayLogs[todayLogs.length - 1 - index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(log.material?.name ?? 'Unknown Material'),
                                  subtitle: Text(
                                    'Used ${log.quantity} ${log.material?.unitDisplay ?? ''} • ${DateFormat('HH:mm').format(log.createdAt)}',
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
                    const SizedBox(height: 24),
                    
                    // Recent Material Updates
                    const Text(
                      'Available Materials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    materials.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No materials available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: materials.length > 5 ? 5 : materials.length,
                            itemBuilder: (context, index) {
                              final material = materials[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(material.name),
                                  subtitle: Text(
                                    '${material.stockQuantity} ${material.unitDisplay} available',
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.inventory,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  trailing: StockStatusBadge(
                                    stockQuantity: material.stockQuantity,
                                    minimumStockLevel: material.minimumStockLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Material'),
        onPressed: () {
          // Navigate to scanner screen
        },
      ),
    );
  }
} 