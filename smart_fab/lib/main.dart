import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/screens/admin/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  try {
    await Hive.initFlutter();
    
    // Web platform handling
    if (kIsWeb) {
      // On web, we'll only use in-memory storage and avoid persistent boxes
      debugPrint('Running on web platform - using in-memory storage only');
    } else {
      // Only try to open boxes if not running in a browser environment
      try {
        if (!Hive.isBoxOpen(AppConstants.materialsBox)) {
          await Hive.openBox(AppConstants.materialsBox);
        }
        if (!Hive.isBoxOpen(AppConstants.processesBox)) {
          await Hive.openBox(AppConstants.processesBox);
        }
        if (!Hive.isBoxOpen(AppConstants.consumptionLogsBox)) {
          await Hive.openBox(AppConstants.consumptionLogsBox);
        }
      } catch (e) {
        debugPrint('Error opening Hive boxes: $e');
      }
    }
  } catch (e) {
    debugPrint('Failed to initialize Hive: $e');
  }
  
  // Set up error handling for Flutter web
  if (kIsWeb) {
    // Override error presentation to handle Firebase and other web-specific errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Additional web-specific error handling
      debugPrint('Flutter error caught in web: ${details.exception}');
      
      // Prevent Firebase errors from crashing the app
      if (details.exception.toString().contains('Firebase') || 
          details.exception.toString().contains('JavaScriptObject')) {
        debugPrint('Suppressing Firebase error in web platform');
        // Don't propagate the error further to prevent app crash
        return;
      }
    };
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // Go directly to admin screen
      home: const AdminScreen(),
      builder: (context, child) {
        // Add error handling at the app level
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // For Firebase errors on web, show a simplified error screen
          final isFirebaseError = details.exception.toString().contains('Firebase') ||
                                  details.exception.toString().contains('JavaScriptObject');
          
          return Material(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (isFirebaseError && kIsWeb)
                    const Text(
                      'Firebase service unavailable in this environment.',
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      kDebugMode ? details.exception.toString() : 'Please try again later',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      );
                    },
                    child: const Text('Return to Admin Screen'),
                  ),
                ],
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}
