import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/services.dart';
import 'package:smart_fab/widgets/widgets.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  MaterialModel? _scannedMaterial;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();
  bool _showForm = false;
  ProcessModel? _selectedProcess;

  @override
  void dispose() {
    _controller.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _resetScan() {
    setState(() {
      _scannedMaterial = null;
      _errorMessage = null;
      _showForm = false;
      _isProcessing = false;
      _quantityController.clear();
      _durationController.clear();
      _notesController.clear();
      _selectedProcess = null;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _scannedMaterial != null) return;

    setState(() {
      _isProcessing = true;
    });

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'No barcode detected';
      });
      return;
    }

    final barcode = barcodes.first.rawValue;
    if (barcode == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Invalid barcode data';
      });
      return;
    }

    try {
      final result = await ref.read(scannerServiceProvider).handleScan(barcode);
      
      if (result['result'] == ScanResult.success) {
        setState(() {
          _scannedMaterial = result['material'] as MaterialModel;
          _showForm = true;
          _errorMessage = null;
          
          // Pre-select first process if available
          final processes = ref.read(processesProvider);
          if (processes.isNotEmpty) {
            _selectedProcess = processes.first;
          }
        });
        
        // Pause scanner for better performance
        await _controller.stop();
        _quantityFocusNode.requestFocus();
      } else {
        setState(() {
          _errorMessage = result['message'] as String;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _logConsumption() async {
    if (_scannedMaterial == null || _selectedProcess == null) {
      setState(() {
        _errorMessage = 'Please select a process';
      });
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid quantity';
      });
      return;
    }

    final duration = double.tryParse(_durationController.text);
    if (duration != null && duration < 0) {
      setState(() {
        _errorMessage = 'Please enter a valid duration';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(consumptionLogServiceProvider).logConsumption(
        materialId: _scannedMaterial!.id,
        processId: _selectedProcess!.id,
        quantity: quantity,
        processDurationHours: duration,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material usage logged successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error logging usage: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final processes = ref.watch(processesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Material'),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              _controller.toggleTorch();
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
            },
          ),
          if (_scannedMaterial != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _resetScan();
                _controller.start();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_scannedMaterial == null)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 250,
                    height: 250,
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: LoadingIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Material Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _scannedMaterial!.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'QR Code: ${_scannedMaterial!.qrCode}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Unit Cost: ₹${_scannedMaterial!.unitCost.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          StockStatusBadge(
                                            stockQuantity: _scannedMaterial!.stockQuantity,
                                            minimumStockLevel: _scannedMaterial!.minimumStockLevel,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Current Stock: ${_scannedMaterial!.stockQuantity} ${_scannedMaterial!.unitDisplay}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Usage Form
                    if (_showForm) ...[
                      const Text(
                        'Log Material Usage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Process Dropdown
                      DropdownButtonFormField<ProcessModel>(
                        decoration: const InputDecoration(
                          labelText: 'Select Process',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProcess,
                        items: processes.map((process) {
                          return DropdownMenuItem<ProcessModel>(
                            value: process,
                            child: Text(process.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProcess = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Quantity Field
                      TextFormField(
                        controller: _quantityController,
                        focusNode: _quantityFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Quantity (${_scannedMaterial!.unitDisplay})',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      
                      // Duration Field
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Process Duration (hours, optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      
                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Cost Preview
                      if (_quantityController.text.isNotEmpty &&
                          double.tryParse(_quantityController.text) != null)
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cost Preview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Material Cost:'),
                                    Text(
                                      '₹${(_scannedMaterial!.unitCost * double.parse(_quantityController.text)).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                if (_selectedProcess != null &&
                                    _durationController.text.isNotEmpty &&
                                    double.tryParse(_durationController.text) != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Processing Cost:'),
                                      Text(
                                        '₹${(_selectedProcess!.totalCostPerHour * double.parse(_durationController.text)).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Manufacturing Cost:'),
                                      Text(
                                        '₹${(_scannedMaterial!.unitCost * double.parse(_quantityController.text) + _selectedProcess!.totalCostPerHour * double.parse(_durationController.text)).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _logConsumption,
                          child: _isLoading
                              ? const LoadingIndicator(size: 24)
                              : const Text('Log Material Usage'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 