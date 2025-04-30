import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:smart_fab/core/app_constants.dart';
import 'package:smart_fab/models/user_model.dart';

class LoginService {
  // For web platform, we'll keep the current user in memory
  static UserModel? _currentWebUser;
  
  // Create a default admin user
  static final UserModel _defaultAdmin = UserModel(
    id: '1',
    name: 'Admin User',
    email: 'admin@example.com',
    password: 'admin1',
    role: 'admin',
  );

  /// Authenticates a user with email and password
  /// In this version, always returns a mock admin user
  Future<UserModel> authenticate(String email, String password) async {
    // Just return the admin user directly, skipping authentication
    if (kIsWeb) {
      _currentWebUser = _defaultAdmin;
      debugPrint('Auto-logged in on web: ${_defaultAdmin.name}');
    } else {
      try {
        final box = await _getUserBox();
        await box.put(AppConstants.currentUserKey, _defaultAdmin.toMap());
        debugPrint('Auto-authenticated and saved: ${_defaultAdmin.name}');
      } catch (e) {
        debugPrint('Error saving user: $e');
      }
    }
    return _defaultAdmin;
  }

  /// Gets the current logged-in user
  Future<UserModel> getCurrentUser() async {
    // Always return the default admin user
    return _defaultAdmin;
  }

  /// Logs out the current user - does nothing in this simplified version
  Future<bool> logout() async {
    debugPrint('Logout called - but we always stay logged in as admin');
    return true;
  }

  /// Helper method to get the user box
  Future<Box> _getUserBox() async {
    if (!Hive.isBoxOpen(AppConstants.userBox)) {
      return await Hive.openBox(AppConstants.userBox);
    }
    return Hive.box(AppConstants.userBox);
  }
} 