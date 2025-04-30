import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smart_fab/models/models.dart';
import 'package:smart_fab/services/mock_firebase_service.dart';
import 'package:smart_fab/utils/unit_type_helper.dart';
import 'package:uuid/uuid.dart';

class MaterialService extends ChangeNotifier {
  // We'll conditionally use either real Firebase or our mock service
  late final FirebaseFirestore? _firestore;
  late final Box<Map> _materialsBox;
  final Connectivity _connectivity = Connectivity();
  List<MaterialModel> _materials = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  // Constructor
  MaterialService() {
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
      debugPrint('Web platform detected - using mock Firebase service');
    }
    
    // Initialize Hive box
    try {
      _materialsBox = Hive.box<Map>('materials');
    } catch (e) {
      debugPrint('Error opening materials box: $e - using in-memory materials');
      // Create in-memory box fallback
      _materials = [];
    }
    
    _initConnectivityListener();
    _loadMaterialsFromLocal();
    
    // Add mock data if there are no materials
    _addMockMaterialsIfEmpty();
  }
  
  // Add mock materials if the list is empty
  Future<void> _addMockMaterialsIfEmpty() async {
    if (_materials.isEmpty) {
      debugPrint('No materials found, adding mock data');
      
      // Wait a moment to allow UI to render first
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Add some mock materials
      await addMaterial(
        name: 'Cotton Fabric',
        qrCode: 'COTTON001',
        unitCost: 150.00,
        unitType: UnitTypeHelper.getByName('meters'),
        stockQuantity: 500.0,
        minimumStockLevel: 100.0,
        description: 'High quality cotton fabric, 150 GSM',
        image: 'https://example.com/cotton.jpg',
      );
      
      await addMaterial(
        name: 'Silk Fabric',
        qrCode: 'SILK001',
        unitCost: 450.00,
        unitType: UnitTypeHelper.getByName('meters'),
        stockQuantity: 120.0,
        minimumStockLevel: 50.0,
        description: 'Premium silk fabric, imported',
        image: 'https://example.com/silk.jpg',
      );
      
      await addMaterial(
        name: 'Denim Fabric',
        qrCode: 'DENIM001',
        unitCost: 280.00,
        unitType: UnitTypeHelper.getByName('meters'),
        stockQuantity: 350.0,
        minimumStockLevel: 75.0,
        description: 'Heavy duty denim, 12oz',
        image: 'https://example.com/denim.jpg',
      );
      
      await addMaterial(
        name: 'Polyester Thread',
        qrCode: 'THREAD001',
        unitCost: 25.00,
        unitType: UnitTypeHelper.getByName('kilograms'),
        stockQuantity: 30.0,
        minimumStockLevel: 10.0,
        description: 'All-purpose sewing thread',
        image: 'https://example.com/thread.jpg',
      );
      
      await addMaterial(
        name: 'Brass Buttons',
        qrCode: 'BUTTON001',
        unitCost: 2.50,
        unitType: UnitTypeHelper.getByName('pieces'),
        stockQuantity: 1000.0,
        minimumStockLevel: 200.0,
        description: 'Metal buttons for jackets and coats',
        image: 'https://example.com/button.jpg',
      );
      
      await addMaterial(
        name: 'Leather',
        qrCode: 'LEATHER001',
        unitCost: 800.00,
        unitType: UnitTypeHelper.getByName('squareFeet'),
        stockQuantity: 75.0,
        minimumStockLevel: 20.0,
        description: 'Genuine cow leather for premium items',
        image: 'https://example.com/leather.jpg',
      );
      
      await addMaterial(
        name: 'Zipper',
        qrCode: 'ZIP001',
        unitCost: 15.00,
        unitType: UnitTypeHelper.getByName('pieces'),
        stockQuantity: 500.0,
        minimumStockLevel: 100.0,
        description: 'Metal zippers, various sizes',
        image: 'https://example.com/zipper.jpg',
      );
      
      // Add a low-stock material to test alerts
      await addMaterial(
        name: 'Elastic Band',
        qrCode: 'ELASTIC001',
        unitCost: 35.00,
        unitType: UnitTypeHelper.getByName('meters'),
        stockQuantity: 10.0,
        minimumStockLevel: 50.0,
        description: 'Elastic band for waistbands',
        image: 'https://example.com/elastic.jpg',
      );
      
      debugPrint('Added ${_materials.length} mock materials');
    }
  }

  // Getters
  List<MaterialModel> get materials => _materials;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  List<MaterialModel> get lowStockMaterials => _materials.where((m) => m.isLowStock).toList();

  // Initialize connectivity listener for sync
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncWithCloud();
      }
    });
  }

  // Load materials from local storage
  Future<void> _loadMaterialsFromLocal() async {
    try {
      final materialsData = _materialsBox.values.toList();
      _materials = materialsData
          .map((data) => MaterialModel.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading materials from local: $e');
    }
  }

  // Fetch materials from Firebase
  Future<void> fetchMaterials({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        // Offline: use local data
        await _loadMaterialsFromLocal();
      } else {
        // Online: fetch from Firebase or use mock
        if (kIsWeb || _firestore == null) {
          // Use mock for web
          debugPrint('Using mock Firebase service for fetchMaterials');
          final mockData = await MockFirebaseService.mockGetCollection(
            collection: 'materials',
            defaultData: _materials.map((m) => m.toMap()).toList(),
          );
          
          _materials = mockData
              .map((data) => MaterialModel.fromMap(Map<String, dynamic>.from(data)))
              .toList();
        } else {
          // Use real Firebase for non-web
          final snapshot = await _firestore!.collection('materials').get();
          _materials = snapshot.docs
              .map((doc) => MaterialModel.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();
        }

        // Update local cache
        await _updateLocalCache();
      }
    } catch (e) {
      debugPrint('Error fetching materials: $e');
      // Fallback to local data on error
      await _loadMaterialsFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update local cache
  Future<void> _updateLocalCache() async {
    try {
      // Clear existing data
      await _materialsBox.clear();

      // Add all materials to local storage
      for (final material in _materials) {
        await _materialsBox.put(material.id, material.toMap());
      }
    } catch (e) {
      debugPrint('Error updating local cache: $e');
    }
  }

  // Get material by ID
  MaterialModel? getMaterialById(String id) {
    try {
      return _materials.firstWhere((material) => material.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get material by QR code
  MaterialModel? getMaterialByQrCode(String qrCode) {
    try {
      return _materials.firstWhere((material) => material.qrCode == qrCode);
    } catch (e) {
      return null;
    }
  }

  // Add material
  Future<MaterialModel?> addMaterial({
    required String name,
    required String qrCode,
    required double unitCost,
    required UnitType unitType,
    required double stockQuantity,
    required double minimumStockLevel,
    String? description,
    String? image,
  }) async {
    try {
      final now = DateTime.now();
      final id = const Uuid().v4();
      
      final material = MaterialModel(
        id: id,
        name: name,
        qrCode: qrCode,
        unitCost: unitCost,
        unitType: unitType,
        stockQuantity: stockQuantity,
        minimumStockLevel: minimumStockLevel,
        description: description,
        image: image,
        createdAt: now,
        updatedAt: now,
      );

      // Add to local storage
      await _materialsBox.put(id, material.toMap());
      
      // Add to memory
      _materials.add(material);
      notifyListeners();

      // Add to Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        if (kIsWeb || _firestore == null) {
          // Use mock for web
          await MockFirebaseService.mockSetDocument(
            collection: 'materials',
            documentId: id,
            data: material.toMap(),
          );
        } else {
          // Use real Firebase for non-web
          await _firestore!.collection('materials').doc(id).set(material.toMap());
        }
      }

      return material;
    } catch (e) {
      debugPrint('Error adding material: $e');
      return null;
    }
  }

  // Update material
  Future<bool> updateMaterial({
    required String id,
    String? name,
    String? qrCode,
    double? unitCost,
    UnitType? unitType,
    double? stockQuantity,
    double? minimumStockLevel,
    String? description,
    String? image,
  }) async {
    try {
      final index = _materials.indexWhere((m) => m.id == id);
      if (index == -1) return false;

      final material = _materials[index];
      final updatedMaterial = material.copyWith(
        name: name,
        qrCode: qrCode,
        unitCost: unitCost,
        unitType: unitType,
        stockQuantity: stockQuantity,
        minimumStockLevel: minimumStockLevel,
        description: description,
        image: image,
        updatedAt: DateTime.now(),
      );

      // Update local storage
      await _materialsBox.put(id, updatedMaterial.toMap());
      
      // Update memory
      _materials[index] = updatedMaterial;
      notifyListeners();

      // Update Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore!.collection('materials').doc(id).update(updatedMaterial.toMap());
      }

      return true;
    } catch (e) {
      debugPrint('Error updating material: $e');
      return false;
    }
  }

  // Delete material
  Future<bool> deleteMaterial(String id) async {
    try {
      final index = _materials.indexWhere((m) => m.id == id);
      if (index == -1) return false;

      // Delete from local storage
      await _materialsBox.delete(id);
      
      // Delete from memory
      _materials.removeAt(index);
      notifyListeners();

      // Delete from Firebase if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore!.collection('materials').doc(id).delete();
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting material: $e');
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
        debugPrint('Sync with cloud attempted on web - using mock sync');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return true;
      }
      
      if (_firestore == null) {
        debugPrint('Firebase not initialized - using mock sync');
        await Future.delayed(const Duration(milliseconds: 500));
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No connectivity - sync aborted');
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      // Push local changes to cloud
      for (final material in _materials) {
        await _firestore!.collection('materials').doc(material.id).set(material.toMap());
      }
      
      debugPrint('Materials synced with cloud');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error syncing with cloud: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
} 