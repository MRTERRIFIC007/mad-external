import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/material_service.dart';
import 'package:smart_fab/services/mock_firebase_service.dart';
import 'package:smart_fab/services/process_service.dart';
import 'package:uuid/uuid.dart';

class ConsumptionLogService extends ChangeNotifier {
  // We'll conditionally use either real Firebase or our mock service
  late final FirebaseFirestore? _firestore;
  late final Box<Map> _logsBox;
  final Connectivity _connectivity = Connectivity();
  final MaterialService materialService;
  final ProcessService processService;
  List<ConsumptionLogModel> _logs = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  // Constructor
  ConsumptionLogService({
    required this.materialService,
    required this.processService,
  }) {
    // Initialize Firebase conditionally
    if (!kIsWeb) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Error initializing Firestore: $e');
        _firestore = null;
      }
    } else {
      _firestore = null;
      debugPrint('Web platform detected - using mock Firebase service for ConsumptionLogService');
    }
    
    // Initialize Hive box
    try {
      _logsBox = Hive.box<Map>('consumptionLogs');
    } catch (e) {
      debugPrint('Error opening consumptionLogs box: $e - using in-memory logs');
      // Create in-memory logs fallback
      _logs = [];
    }
    
    _initConnectivityListener();
    _loadLogsFromLocal();
    
    // Add mock logs after a delay to ensure materials and processes are loaded
    Future.delayed(const Duration(seconds: 1), () {
      _addMockLogsIfEmpty();
    });
  }

  // Getters
  List<ConsumptionLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  // Initialize connectivity listener for sync
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncWithCloud();
      }
    });
  }

  // Load logs from local storage
  Future<void> _loadLogsFromLocal() async {
    try {
      final logsData = _logsBox.values.toList();
      
      _logs = [];
      for (final data in logsData) {
        try {
          final logMap = Map<String, dynamic>.from(data);
          // Make sure we have the necessary fields
          if (!logMap.containsKey('createdAt') || !logMap.containsKey('updatedAt')) {
            // Add required fields with default values if missing
            if (!logMap.containsKey('createdAt')) {
              logMap['createdAt'] = DateTime.now().millisecondsSinceEpoch;
            }
            if (!logMap.containsKey('updatedAt')) {
              logMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
            }
          }
          
          final log = ConsumptionLogModel.fromMap(logMap);
          
          // Attach material and process objects
          final materialId = log.materialId;
          final processId = log.processId;
          
          final material = materialService.getMaterialById(materialId);
          final process = processService.getProcessById(processId);
          
          final enrichedLog = log.copyWith(
            material: material,
            process: process,
          );
          
          _logs.add(enrichedLog);
        } catch (e) {
          debugPrint('Error parsing log: $e');
        }
      }
      
      _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading logs from local: $e');
    }
  }

  // Get logs by date range
  List<ConsumptionLogModel> getLogsByDateRange(DateTime start, DateTime end) {
    return _logs.where((log) =>
      log.createdAt.isAfter(start) && log.createdAt.isBefore(end)
    ).toList();
  }

  // Fetch logs from Firebase
  Future<void> fetchLogs({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        // Offline: use local data
        await _loadLogsFromLocal();
      } else {
        // Online: fetch from Firebase or use mock
        if (kIsWeb || _firestore == null) {
          // Use mock for web
          debugPrint('Using mock Firebase service for fetchLogs');
          final mockData = await MockFirebaseService.mockGetCollection(
            collection: 'consumptionLogs',
            defaultData: _logs.map((l) => l.toMap()).toList(),
          );
          
          _logs = [];
          for (final data in mockData) {
            try {
              final logMap = Map<String, dynamic>.from(data);
              // Make sure we have the necessary fields
              if (!logMap.containsKey('createdAt') || !logMap.containsKey('updatedAt')) {
                // Add required fields with default values if missing
                if (!logMap.containsKey('createdAt')) {
                  logMap['createdAt'] = DateTime.now().millisecondsSinceEpoch;
                }
                if (!logMap.containsKey('updatedAt')) {
                  logMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
                }
              }
              
              final log = ConsumptionLogModel.fromMap(logMap);
              
              // Attach material and process objects
              final materialId = log.materialId;
              final processId = log.processId;
              
              final material = materialService.getMaterialById(materialId);
              final process = processService.getProcessById(processId);
              
              final enrichedLog = log.copyWith(
                material: material,
                process: process,
              );
              
              _logs.add(enrichedLog);
            } catch (e) {
              debugPrint('Error parsing mock log: $e');
            }
          }
        } else {
          // Use real Firebase for non-web
          final snapshot = await _firestore!.collection('consumptionLogs').get();
          
          _logs = [];
          for (final doc in snapshot.docs) {
            try {
              final logMap = {
                'id': doc.id,
                ...doc.data(),
              };
              
              // Make sure we have the necessary fields
              if (!logMap.containsKey('createdAt') || !logMap.containsKey('updatedAt')) {
                // Add required fields with default values if missing
                if (!logMap.containsKey('createdAt')) {
                  logMap['createdAt'] = DateTime.now().millisecondsSinceEpoch;
                }
                if (!logMap.containsKey('updatedAt')) {
                  logMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
                }
              }
              
              final log = ConsumptionLogModel.fromMap(logMap);
              
              // Attach material and process objects
              final materialId = log.materialId;
              final processId = log.processId;
              
              final material = materialService.getMaterialById(materialId);
              final process = processService.getProcessById(processId);
              
              final enrichedLog = log.copyWith(
                material: material,
                process: process,
              );
              
              _logs.add(enrichedLog);
            } catch (e) {
              debugPrint('Error parsing log document: $e');
            }
          }
        }
        
        _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Update local cache
        await _updateLocalCache();
      }
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      // Fallback to local data on error
      await _loadLogsFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _updateLocalCache() async {
    try {
      await _logsBox.clear();

  
      for (final log in _logs) {
        await _logsBox.put(log.id, log.toMap());
      }
    } catch (e) {
      debugPrint('Error updating local cache: $e');
    }
  }

  // Log consumption
  Future<ConsumptionLogModel?> logConsumption({
    required String materialId,
    required String processId,
    required double quantity,
    double? processDurationHours,
    String? productName,
    String? notes,
    DateTime? createdAt,
  }) async {
    try {
      final now = DateTime.now();
      final id = const Uuid().v4();
      
      // Get material and process objects for local usage
      final material = materialService.getMaterialById(materialId);
      final process = processService.getProcessById(processId);
      
      if (material == null) {
        throw Exception('Material not found with id $materialId');
      }
      
      if (process == null) {
        throw Exception('Process not found with id $processId');
      }
      
      // Check if quantity is valid
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than zero');
      }
      
      // Check if there's enough stock
      if (quantity > material.stockQuantity) {
        throw Exception('Not enough stock available. Current stock: ${material.stockQuantity} ${material.unitDisplay}');
      }
      
      final log = ConsumptionLogModel(
        id: id,
        materialId: materialId,
        processId: processId,
        quantity: quantity,
        productName: productName,
        processDurationHours: processDurationHours,
        notes: notes,
        createdAt: createdAt ?? now,
        updatedAt: now,
        material: material,
        process: process,
      );

      // Add to local storage
      await _logsBox.put(id, log.toMap());
      
      // Add to memory
      _logs.add(log);
      _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();

      // Update material stock quantity
      final updatedMaterial = material.copyWith(
        stockQuantity: material.stockQuantity - quantity,
      );
      
      await materialService.updateMaterial(
        id: material.id,
        stockQuantity: updatedMaterial.stockQuantity,
      );

      // Add to Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        if (kIsWeb || _firestore == null) {
          await MockFirebaseService.mockSetDocument(
            collection: 'consumptionLogs',
            documentId: id,
            data: log.toMap(),
          );
        } else {
          await _firestore!.collection('consumptionLogs').doc(id).set(log.toMap());
        }
      }

      return log;
    } catch (e) {
      debugPrint('Error logging consumption: $e');
      return null;
    }
  }

  // Sync with cloud
  Future<bool> syncWithCloud() async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      if (kIsWeb) {
        // On web, just log the sync attempt but don't actually try to use Firebase
        debugPrint('Sync with cloud attempted on web - using mock sync for consumption logs');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return true;
      }
      
      if (_firestore == null) {
        debugPrint('Firebase not initialized - using mock sync for consumption logs');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No connectivity - consumption logs sync aborted');
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      // Push local changes to cloud
      for (final log in _logs) {
        await _firestore!.collection('consumptionLogs').doc(log.id).set(log.toMap());
      }
      
      debugPrint('Consumption logs synced with cloud');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error syncing consumption logs with cloud: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Get logs by material
  List<ConsumptionLogModel> getLogsByMaterial(String materialId) {
    return _logs.where((log) => log.materialId == materialId).toList();
  }

  // Get logs by product
  List<ConsumptionLogModel> getLogsByProduct(String productName) {
    return _logs.where((log) => 
      log.productName != null && 
      log.productName!.toLowerCase().contains(productName.toLowerCase())
    ).toList();
  }

  // Calculate total material cost for a date range
  double calculateTotalMaterialCost(DateTime start, DateTime end) {
    return getLogsByDateRange(start, end)
        .fold(0.0, (sum, log) => sum + log.materialCost);
  }

  // Calculate total processing cost for a date range
  double calculateTotalProcessingCost(DateTime start, DateTime end) {
    return getLogsByDateRange(start, end)
        .fold(0.0, (sum, log) => sum + log.processingCost);
  }

  // Calculate total manufacturing cost for a date range
  double calculateTotalManufacturingCost(DateTime start, DateTime end) {
    return getLogsByDateRange(start, end)
        .fold(0.0, (sum, log) => sum + log.totalManufacturingCost);
  }

  // Add mock consumption logs if the list is empty
  Future<void> _addMockLogsIfEmpty() async {
    if (_logs.isEmpty) {
      debugPrint('No consumption logs found, adding mock data');
      
      final materials = materialService.materials;
      final processes = processService.processes;
      
      if (materials.isEmpty || processes.isEmpty) {
        debugPrint('Cannot add mock logs: materials or processes are not loaded yet');
        return;
      }
      
      // Generate logs for the past 7 days
      final now = DateTime.now();
      var seed = DateTime.now().millisecondsSinceEpoch;
      
      // Product names for mock data
      final List<String> productNames = [
        'T-Shirt',
        'Jeans',
        'Jacket',
        'Dress',
        'Scarf',
        'Bag',
        'Hat',
      ];
      
      // Create a few mock consumption logs
      for (int i = 0; i < 12; i++) {
        // Get pseudorandom numbers
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final materialIndex = seed % materials.length;
        
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final processIndex = seed % processes.length;
        
        // Pick a random material and process
        final material = materials[materialIndex];
        final process = processes[processIndex];
        
        // Generate a random time in the past 7 days
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final hoursAgo = seed % 168; // Up to 7 days in hours
        
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final minutesAgo = seed % 60;
        
        final logDate = now.subtract(Duration(
          hours: hoursAgo, 
          minutes: minutesAgo,
        ));
        
        // Generate a random quantity between 1 and 20
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final quantity = 1.0 + (seed % 20);
        
        // Generate random process duration between 0.5 and 3 hours
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final duration = 0.5 + (seed % 5) / 2;
        
        // Pick a random product name
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        final productNameIndex = seed % productNames.length;
        
        await logConsumption(
          materialId: material.id,
          processId: process.id,
          quantity: quantity,
          processDurationHours: duration,
          productName: productNames[productNameIndex],
          notes: 'Mock consumption log #${i+1}',
          createdAt: logDate,
        );
      }
      
      debugPrint('Added ${_logs.length} mock consumption logs');
    }
  }
} 