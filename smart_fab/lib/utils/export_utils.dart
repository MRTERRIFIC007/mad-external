import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

/// Utility class for handling file exports
class ExportUtils {
  /// Shares a file with other apps
  static Future<void> shareFile(File file) async {
    try {
      if (kIsWeb) {
        debugPrint('File sharing not supported on web platform');
        return;
      }
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Saves a file to the downloads directory
  static Future<bool> saveFileToStorage(File sourceFile, String fileName) async {
    try {
      if (kIsWeb) {
        debugPrint('File saving not supported on web platform');
        return false;
      }
      
      // Check storage permission
      if (!await _requestStoragePermission()) {
        return false;
      }

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getExternalStorageDirectory() ?? 
                   await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? 
                   await getApplicationDocumentsDirectory();
      }
      
      // Copy file to downloads
      final targetPath = '${directory.path}/$fileName';
      await sourceFile.copy(targetPath);
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return false;
    }
  }

  /// Requests storage permission
  static Future<bool> _requestStoragePermission() async {
    if (kIsWeb) {
      return true; // No permissions needed on web
    }
    
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    
    return true; // Assume granted on other platforms
  }

  /// Get a temporary file path
  static Future<String> getTemporaryFilePath(String filename) async {
    if (kIsWeb) {
      return filename; // Just return the filename on web
    }
    
    // Create a unique filename to avoid conflicts
    final uniqueId = Random().nextInt(10000).toString();
    final safeFilename = '${uniqueId}_$filename';
    
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$safeFilename';
  }
} 