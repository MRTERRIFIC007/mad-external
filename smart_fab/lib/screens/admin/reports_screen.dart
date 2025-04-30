import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/services.dart';
import 'package:smart_fab/utils/export_utils.dart';
import 'package:smart_fab/widgets/widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  String? _selectedMaterialId;
  String? _selectedProductName;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
  
  Future<void> _generateConsumptionReport({required bool isPdf}) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    
    try {
      final reportService = ref.read(reportServiceProvider);
      File file;
      
      if (isPdf) {
        file = await reportService.generateConsumptionLogsPdf(
          startDate: _startDate,
          endDate: _endDate,
          materialId: _selectedMaterialId,
          productName: _selectedProductName,
        );
      } else {
        file = await reportService.generateConsumptionLogsCsv(
          startDate: _startDate,
          endDate: _endDate,
          materialId: _selectedMaterialId,
          productName: _selectedProductName,
        );
      }
      
      _showExportOptions(context, file);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate report: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  Future<void> _generateInventoryReport({required bool isPdf}) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    
    try {
      final materials = ref.read(materialsProvider);
      final reportService = ref.read(reportServiceProvider);
      File file;
      
      if (isPdf) {
        file = await reportService.generateInventoryReportPdf(materials);
      } else {
        // Use the CSV generation method
        file = await reportService.generateInventoryCsv(materials);
      }
      
      _showExportOptions(context, file);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate report: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  void _showExportOptions(BuildContext context, File file) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Report'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ExportUtils.shareFile(file);
                  } catch (e) {
                    _showErrorSnackbar('Failed to share file: ${e.toString().split('\n').first}');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save to Device'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final bool success = await ExportUtils.saveFileToStorage(
                      file,
                      file.path.split('/').last,
                    );
                    
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (mounted) {
                      _showErrorSnackbar('Failed to save report. Please check app permissions.');
                    }
                  } catch (e) {
                    _showErrorSnackbar('Error saving file: ${e.toString().split('\n').first}');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final materials = ref.watch(materialsProvider);
    final consumptionLogs = ref.watch(consumptionLogsProvider);
    
    // Extract unique product names from logs
    final Set<String> productNames = {};
    for (final log in consumptionLogs) {
      if (log.productName != null && log.productName!.isNotEmpty) {
        productNames.add(log.productName!);
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Consumption Logs'),
            Tab(text: 'Inventory'),
            Tab(text: 'Cost Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Consumption Logs Report Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consumption Logs Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Range Selector
                        GestureDetector(
                          onTap: () => _selectDateRange(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Material Dropdown
                        DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Filter by Material (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedMaterialId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Materials'),
                            ),
                            ...materials.map((material) {
                              return DropdownMenuItem<String?>(
                                value: material.id,
                                child: Text(material.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedMaterialId = value;
                              if (value != null) {
                                _selectedProductName = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Product Dropdown
                        DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Filter by Product (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedProductName,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Products'),
                            ),
                            ...productNames.map((name) {
                              return DropdownMenuItem<String?>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedProductName = value;
                              if (value != null) {
                                _selectedMaterialId = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        
                        // Generate Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Generate PDF'),
                                onPressed: _isGenerating
                                    ? null
                                    : () => _generateConsumptionReport(isPdf: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.table_chart),
                                label: const Text('Generate CSV'),
                                onPressed: _isGenerating
                                    ? null
                                    : () => _generateConsumptionReport(isPdf: false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isGenerating)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: LoadingIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Inventory Report Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Generate a report of all materials in inventory, including current stock levels, costs, and low stock alerts.',
                        ),
                        const SizedBox(height: 24),
                        
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        
                        // Generate Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Generate PDF Report'),
                                onPressed: _isGenerating
                                    ? null
                                    : () => _generateInventoryReport(isPdf: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.table_chart),
                                label: const Text('Generate CSV Report'),
                                onPressed: _isGenerating
                                    ? null
                                    : () => _generateInventoryReport(isPdf: false),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isGenerating)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: LoadingIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cost Analysis Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Analysis Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'This feature is coming soon! Cost analysis reports will provide detailed breakdowns of manufacturing costs, profit margins, and pricing recommendations.',
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Cost analysis reports will be available in the next update.',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 