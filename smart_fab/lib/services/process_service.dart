import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/mock_firebase_service.dart';
import 'package:uuid/uuid.dart';

class ProcessService extends ChangeNotifier {
  // We'll conditionally use either real Firebase or our mock service
  late final FirebaseFirestore? _firestore;
  late final Box<Map> _processesBox;
  final Connectivity _connectivity = Connectivity();
  List<ProcessModel> _processes = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  // Constructor
  ProcessService() {
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
      debugPrint('Web platform detected - using mock Firebase service for ProcessService');
    }
    
    // Initialize Hive box
    try {
      _processesBox = Hive.box<Map>('processes');
    } catch (e) {
      debugPrint('Error opening processes box: $e - using in-memory processes');
      // Create in-memory processes fallback
      _processes = [];
    }
    
    _initConnectivityListener();
    _loadProcessesFromLocal();
    
    // Add mock processes if empty
    _addMockProcessesIfEmpty();
  }
  
  // Add mock processes if the list is empty
  Future<void> _addMockProcessesIfEmpty() async {
    if (_processes.isEmpty) {
      debugPrint('No processes found, adding mock data');
      
      // Wait a moment to allow UI to render first
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Add some mock processes
      await addProcess(
        name: 'Cutting',
        description: 'Cutting fabric according to patterns',
        laborCostPerHour: 120.0,
        energyCostPerHour: 30.0,
        otherCostsPerHour: 10.0,
      );
      
      await addProcess(
        name: 'Stitching',
        description: 'Sewing pieces together',
        laborCostPerHour: 150.0,
        energyCostPerHour: 40.0,
        otherCostsPerHour: 15.0,
      );
      
      await addProcess(
        name: 'Embroidery',
        description: 'Adding decorative designs',
        laborCostPerHour: 200.0,
        energyCostPerHour: 50.0,
        otherCostsPerHour: 25.0,
      );
      
      await addProcess(
        name: 'Dyeing',
        description: 'Coloring fabric with dyes',
        laborCostPerHour: 160.0,
        energyCostPerHour: 80.0,
        otherCostsPerHour: 60.0,
      );
      
      await addProcess(
        name: 'Quality Check',
        description: 'Inspecting finished products',
        laborCostPerHour: 140.0,
        energyCostPerHour: 20.0,
        otherCostsPerHour: 5.0,
      );
      
      await addProcess(
        name: 'Packaging',
        description: 'Preparing products for shipping',
        laborCostPerHour: 100.0,
        energyCostPerHour: 25.0,
        otherCostsPerHour: 40.0,
      );
      
      await addProcess(
        name: 'Printing',
        description: 'Adding prints to fabric',
        laborCostPerHour: 180.0,
        energyCostPerHour: 70.0,
        otherCostsPerHour: 55.0,
      );
      
      debugPrint('Added ${_processes.length} mock processes');
    }
  }

  // Getters
  List<ProcessModel> get processes => _processes;
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

  // Load processes from local storage
  Future<void> _loadProcessesFromLocal() async {
    try {
      final processesData = _processesBox.values.toList();
      _processes = processesData
          .map((data) => ProcessModel.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading processes from local: $e');
    }
  }

  // Fetch processes from Firebase
  Future<void> fetchProcesses({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        // Offline: use local data
        await _loadProcessesFromLocal();
      } else {
        // Online: fetch from Firebase or use mock
        if (kIsWeb || _firestore == null) {
          // Use mock for web
          debugPrint('Using mock Firebase service for fetchProcesses');
          final mockData = await MockFirebaseService.mockGetCollection(
            collection: 'processes',
            defaultData: _processes.map((p) => p.toMap()).toList(),
          );
          
          _processes = mockData
              .map((data) => ProcessModel.fromMap(Map<String, dynamic>.from(data)))
              .toList();
        } else {
          // Use real Firebase for non-web
          final snapshot = await _firestore!.collection('processes').get();
          _processes = snapshot.docs
              .map((doc) => ProcessModel.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();
        }

        // Update local cache
        await _updateLocalCache();
      }
    } catch (e) {
      debugPrint('Error fetching processes: $e');
      // Fallback to local data on error
      await _loadProcessesFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update local cache
  Future<void> _updateLocalCache() async {
    try {
      // Clear existing data
      await _processesBox.clear();

      // Add all processes to local storage
      for (final process in _processes) {
        await _processesBox.put(process.id, process.toMap());
      }
    } catch (e) {
      debugPrint('Error updating local cache: $e');
    }
  }

  // Get process by ID
  ProcessModel? getProcessById(String id) {
    try {
      return _processes.firstWhere((process) => process.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add process
  Future<ProcessModel?> addProcess({
    required String name,
    required String description,
    required double laborCostPerHour,
    required double energyCostPerHour,
    required double otherCostsPerHour,
  }) async {
    try {
      final now = DateTime.now();
      final id = const Uuid().v4();
      
      final process = ProcessModel(
        id: id,
        name: name,
        description: description,
        laborCostPerHour: laborCostPerHour,
        energyCostPerHour: energyCostPerHour,
        otherCostsPerHour: otherCostsPerHour,
        createdAt: now,
        updatedAt: now,
      );

      // Add to local storage
      await _processesBox.put(id, process.toMap());
      
      // Add to memory
      _processes.add(process);
      notifyListeners();

      // Add to Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore!.collection('processes').doc(id).set(process.toMap());
      }

      return process;
    } catch (e) {
      debugPrint('Error adding process: $e');
      return null;
    }
  }

  // Update process
  Future<bool> updateProcess({
    required String id,
    String? name,
    String? description,
    double? laborCostPerHour,
    double? energyCostPerHour,
    double? otherCostsPerHour,
  }) async {
    try {
      final index = _processes.indexWhere((p) => p.id == id);
      if (index == -1) return false;

      final process = _processes[index];
      final updatedProcess = process.copyWith(
        name: name,
        description: description,
        laborCostPerHour: laborCostPerHour,
        energyCostPerHour: energyCostPerHour,
        otherCostsPerHour: otherCostsPerHour,
        updatedAt: DateTime.now(),
      );

      // Update local storage
      await _processesBox.put(id, updatedProcess.toMap());
      
      // Update memory
      _processes[index] = updatedProcess;
      notifyListeners();

      // Update Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore!.collection('processes').doc(id).update(updatedProcess.toMap());
      }

      return true;
    } catch (e) {
      debugPrint('Error updating process: $e');
      return false;
    }
  }

  // Delete process
  Future<bool> deleteProcess(String id) async {
    try {
      final index = _processes.indexWhere((p) => p.id == id);
      if (index == -1) return false;

      // Delete from local storage
      await _processesBox.delete(id);
      
      // Delete from memory
      _processes.removeAt(index);
      notifyListeners();

      // Delete from Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore!.collection('processes').doc(id).delete();
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting process: $e');
      return false;
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
        debugPrint('Sync with cloud attempted on web - using mock sync for processes');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return true;
      }
      
      if (_firestore == null) {
        debugPrint('Firebase not initialized - using mock sync for processes');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No connectivity - process sync aborted');
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      // Push local changes to cloud
      for (final process in _processes) {
        await _firestore!.collection('processes').doc(process.id).set(process.toMap());
      }
      
      debugPrint('Processes synced with cloud');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error syncing processes with cloud: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
} 