import 'package:flutter/foundation.dart';

/// A class to provide mock Firebase functionality when running on web
/// This is a temporary solution to avoid Firebase initialization errors on web
class MockFirebaseService {
  // Singleton pattern
  static final MockFirebaseService _instance = MockFirebaseService._internal();
  factory MockFirebaseService() => _instance;
  MockFirebaseService._internal();

  /// Use this method to check if we should use mock Firebase
  /// Always returns true for web platform
  static bool shouldUseMock() {
    return kIsWeb;
  }

  /// A mock method to substitute any Firebase operation
  /// Returns a Future that resolves to the provided defaultValue
  static Future<T> mockOperation<T>(T defaultValue, {String? operationName}) async {
    // Add a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firebase operation${operationName != null ? " ($operationName)" : ""} returning default value');
    return defaultValue;
  }

  /// A mock Firestore-like get operation
  static Future<Map<String, dynamic>> mockGetDocument({
    required String collection,
    required String documentId,
    Map<String, dynamic> defaultData = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firestore get document: $collection/$documentId');
    return {'id': documentId, ...defaultData};
  }

  /// A mock Firestore-like collection get operation
  static Future<List<Map<String, dynamic>>> mockGetCollection({
    required String collection,
    List<Map<String, dynamic>> defaultData = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firestore get collection: $collection');
    return defaultData;
  }

  /// A mock Firestore-like set operation
  static Future<void> mockSetDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firestore set document: $collection/$documentId');
    debugPrint('Data: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
    return;
  }

  /// A mock Firestore-like add operation
  static Future<String> mockAddDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final documentId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('Mock Firestore add document: $collection/$documentId');
    return documentId;
  }

  /// A mock Firestore-like update operation
  static Future<void> mockUpdateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firestore update document: $collection/$documentId');
    debugPrint('Data: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
    return;
  }

  /// A mock Firestore-like delete operation
  static Future<void> mockDeleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('Mock Firestore delete document: $collection/$documentId');
    return;
  }
} 