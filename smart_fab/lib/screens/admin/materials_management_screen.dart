import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/services.dart';
import 'package:smart_fab/widgets/widgets.dart';

class MaterialsManagementScreen extends ConsumerStatefulWidget {
  const MaterialsManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MaterialsManagementScreen> createState() => _MaterialsManagementScreenState();
}

class _MaterialsManagementScreenState extends ConsumerState<MaterialsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _minimumStockLevelController = TextEditingController();
  final _unitDisplayController = TextEditingController();
  String? _selectedMaterialId;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _qrCodeController.dispose();
    _descriptionController.dispose();
    _unitCostController.dispose();
    _stockQuantityController.dispose();
    _minimumStockLevelController.dispose();
    _unitDisplayController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _nameController.clear();
      _qrCodeController.clear();
      _descriptionController.clear();
      _unitCostController.clear();
      _stockQuantityController.clear();
      _minimumStockLevelController.clear();
      _unitDisplayController.clear();
      _selectedMaterialId = null;
      _isEditing = false;
      _errorMessage = null;
    });
  }

  void _editMaterial(MaterialModel material) {
    setState(() {
      _selectedMaterialId = material.id;
      _nameController.text = material.name;
      _qrCodeController.text = material.qrCode;
      _descriptionController.text = material.description ?? '';
      _unitCostController.text = material.unitCost.toString();
      _stockQuantityController.text = material.stockQuantity.toString();
      _minimumStockLevelController.text = material.minimumStockLevel.toString();
      _unitDisplayController.text = material.unitDisplay;
      _isEditing = true;
      _errorMessage = null;
    });
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final materialService = ref.read(materialServiceProvider);
      
      // Convert form data to required parameters
      final name = _nameController.text;
      final qrCode = _qrCodeController.text;
      final unitCost = double.parse(_unitCostController.text);
      final stockQuantity = double.parse(_stockQuantityController.text);
      final minimumStockLevel = double.parse(_minimumStockLevelController.text);
      final unitDisplay = _unitDisplayController.text;
      final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
      
      bool success = false;

      if (_isEditing && _selectedMaterialId != null) {
        // Update existing material
        success = await materialService.updateMaterial(
          id: _selectedMaterialId!,
          name: name,
          qrCode: qrCode,
          unitCost: unitCost,
          stockQuantity: stockQuantity,
          minimumStockLevel: minimumStockLevel,
          description: description,
        );
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material updated successfully')),
          );
        }
      } else {
        // Create new material
        final newMaterial = await materialService.addMaterial(
          name: name,
          qrCode: qrCode,
          unitCost: unitCost,
          unitType: UnitType.piece, // Default to piece
          stockQuantity: stockQuantity,
          minimumStockLevel: minimumStockLevel,
          description: description,
        );
        
        if (mounted && newMaterial != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material added successfully')),
          );
          success = true;
        }
      }

      if (success) {
        _resetForm();
      } else {
        setState(() {
          _errorMessage = 'Failed to save material. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving material: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMaterial(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(materialServiceProvider).deleteMaterial(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted successfully')),
        );
      }

      if (_selectedMaterialId == id) {
        _resetForm();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting material: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, MaterialModel material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete ${material.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMaterial(material.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialsProvider);
    final materialService = ref.watch(materialServiceProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => materialService.fetchMaterials(forceRefresh: true),
            tooltip: 'Refresh Materials',
          ),
        ],
      ),
      body: materialService.isLoading && materials.isEmpty
          ? const Center(child: LoadingIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Materials List
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'All Materials',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('New Material'),
                                  onPressed: _resetForm,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: materials.length,
                              itemBuilder: (context, index) {
                                final material = materials[index];
                                return ListTile(
                                  title: Text(material.name),
                                  subtitle: Text(
                                    'QR: ${material.qrCode} | Stock: ${material.stockQuantity} ${material.unitDisplay}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(material.unitCost),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editMaterial(material),
                                        tooltip: 'Edit Material',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteConfirmation(context, material),
                                        tooltip: 'Delete Material',
                                      ),
                                    ],
                                  ),
                                  selected: _selectedMaterialId == material.id,
                                  selectedTileColor: Colors.blue.shade50,
                                  onTap: () => _editMaterial(material),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Material Form
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'Edit Material' : 'Add New Material',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
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
                              
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Name
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Material Name *',
                                          hintText: 'Enter material name',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter material name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // QR Code
                                      TextFormField(
                                        controller: _qrCodeController,
                                        decoration: const InputDecoration(
                                          labelText: 'QR Code *',
                                          hintText: 'Enter QR code',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter QR code';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Description
                                      TextFormField(
                                        controller: _descriptionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Description',
                                          hintText: 'Enter description (optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Row for cost and unit
                                      Row(
                                        children: [
                                          // Unit Cost
                                          Expanded(
                                            child: TextFormField(
                                              controller: _unitCostController,
                                              decoration: const InputDecoration(
                                                labelText: 'Unit Cost *',
                                                hintText: 'Enter cost per unit',
                                                prefixText: '₹',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter unit cost';
                                                }
                                                if (double.tryParse(value) == null) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Unit Display
                                          Expanded(
                                            child: TextFormField(
                                              controller: _unitDisplayController,
                                              decoration: const InputDecoration(
                                                labelText: 'Unit Type *',
                                                hintText: 'e.g., kg, m, pcs',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter unit type';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Row for stock quantities
                                      Row(
                                        children: [
                                          // Current Stock
                                          Expanded(
                                            child: TextFormField(
                                              controller: _stockQuantityController,
                                              decoration: const InputDecoration(
                                                labelText: 'Current Stock *',
                                                hintText: 'Enter current quantity',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter current stock';
                                                }
                                                if (double.tryParse(value) == null) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Minimum Stock Level
                                          Expanded(
                                            child: TextFormField(
                                              controller: _minimumStockLevelController,
                                              decoration: const InputDecoration(
                                                labelText: 'Minimum Stock Level *',
                                                hintText: 'Enter minimum level',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter minimum stock';
                                                }
                                                if (double.tryParse(value) == null) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading ? null : _resetForm,
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _saveMaterial,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(150, 45),
                                    ),
                                    child: _isLoading
                                        ? const LoadingIndicator(size: 24)
                                        : Text(_isEditing ? 'Update Material' : 'Add Material'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 