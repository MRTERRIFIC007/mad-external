import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_fab/core/app_constants.dart';
import 'package:smart_fab/models/models.dart';

class AppInit {
  /// Initialize all app dependencies
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Hive
    await _initializeHive();
    
    // Initialize Firebase (not needed for this prototype)
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Initialize Hive for local storage
  static Future<void> _initializeHive() async {
    final appDocumentDirectory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDirectory.path);
    
    // Open Hive boxes
    await Hive.openBox<Map>(AppConstants.materialsBox);
    await Hive.openBox<Map>(AppConstants.processesBox);
    await Hive.openBox<Map>(AppConstants.consumptionLogsBox);
    await Hive.openBox<Map>(AppConstants.userBox);
  }
} 