import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_fab/core/app_constants.dart';
import 'package:smart_fab/models/models.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.authenticated; // Always authenticated
  Box? _userBox;
  
  // Static admin user that is always returned
  static final UserModel _defaultAdmin = UserModel(
    id: 'admin123',
    name: 'Admin User',
    email: 'admin@smartfab.com',
    password: 'admin1',
    role: AppConstants.adminRole,
  );
  
  AuthService() {
    // Set the current user to admin immediately
    _currentUser = _defaultAdmin;
    
    // Try to initialize box asynchronously
    _initBox();
  }
  
  Future<void> _initBox() async {
    try {
      if (Hive.isBoxOpen(AppConstants.userBox)) {
        _userBox = Hive.box(AppConstants.userBox);
      } else {
        _userBox = await Hive.openBox(AppConstants.userBox);
      }
      // Store the user for persistence
      await _userBox?.put(AppConstants.currentUserKey, _defaultAdmin.toMap());
    } catch (e) {
      debugPrint('Error initializing user box: $e');
    }
  }
  
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => true; // Always authenticated
  bool get isAdmin => true; // Always admin
  
  // This method now just returns success immediately
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    debugPrint('Authentication bypassed, using default admin user');
    // We're already logged in, no need to do anything
    return;
  }
  
  // This method now does nothing
  Future<void> signOut() async {
    debugPrint('Logout bypassed, staying logged in as admin');
    // No need to actually log out
    return;
  }
} 